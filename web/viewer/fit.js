// Avatar + outfit fitting viewer.
//
// Every outfit GLB is skinned to the same bone names as avatar.glb (made by beandoche_osee_modeling/pipeline).
// On load the outfit's SkinnedMesh is re-bound to the avatar's skeleton, so body and clothes are driven by
// one set of bones and can never drift apart. Skin covered by the current outfit is hidden with the
// `_cover_<outfit>` vertex attribute baked into avatar.glb, so it cannot poke through the clothes.
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const params = new URLSearchParams(location.search);
// Flutter build: assets/modeling_glb/fitted/. Override with ?base=<url>/ for other hosts.
const BASE = params.get('base') ?? new URL('../assets/modeling_glb/fitted/', location.href).href;
const statusEl = document.querySelector('#status');

// ---------------------------------------------------------------- scene
const scene = new THREE.Scene();
scene.background = new THREE.Color('#eeeae4');
const camera = new THREE.PerspectiveCamera(35, innerWidth / innerHeight, 0.01, 100);
camera.position.set(0, 1.2, 4.2);
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
document.body.appendChild(renderer.domElement);
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 1.0, 0);
controls.enableDamping = true;
scene.add(new THREE.HemisphereLight(0xffffff, 0x8a8178, 1.6));
const key = new THREE.DirectionalLight(0xffffff, 2.2); key.position.set(2, 4, 3); scene.add(key);
const rim = new THREE.DirectionalLight(0xffffff, 0.8); rim.position.set(-3, 2, -3); scene.add(rim);

const loader = new GLTFLoader();
let body, skeleton, wornMeshes = [], outfits = [], current = null;

// ---------------------------------------------------------------- skin hiding (cover mask)
function installCoverMask(mesh) {
      const geo = mesh.geometry;
      geo.setAttribute('coverMask', new THREE.BufferAttribute(new Float32Array(geo.attributes.position.count), 1));
      mesh.material.onBeforeCompile = (shader) => {
            shader.vertexShader = shader.vertexShader
                  .replace('#include <common>', '#include <common>\nattribute float coverMask;\nvarying float vCover;')
                  .replace('#include <begin_vertex>', '#include <begin_vertex>\nvCover = coverMask;');
            shader.fragmentShader = shader.fragmentShader
                  .replace('#include <common>', '#include <common>\nvarying float vCover;')
                  .replace('void main() {', 'void main() {\n  if (vCover > 0.5) discard;');
      };
      mesh.material.needsUpdate = true;
}

function setCover(attrName) {
      const geo = body.geometry;
      // GLTFLoader lower-cases custom attribute names
      const src = attrName && geo.getAttribute(attrName.toLowerCase());
      const dst = geo.getAttribute('coverMask');
      if (src) dst.array.set(src.array); else dst.array.fill(0);
      dst.needsUpdate = true;
}

// ---------------------------------------------------------------- outfits
async function wear(outfit) {
      wornMeshes.forEach((m) => { m.parent?.remove(m); m.geometry.dispose(); });
      wornMeshes = [];
      current = outfit;
      document.querySelectorAll('#outfits button').forEach((b) => b.classList.toggle('on', b.dataset.id === (outfit?.id ?? '')));
      if (!outfit) { setCover(null); return; }
      statusEl.textContent = `${outfit.id} 불러오는 중...`;
      const gltf = await loader.loadAsync(BASE + outfit.file);
      if (current !== outfit) return;                                  // user switched meanwhile
      const meshes = [];
      gltf.scene.traverse((o) => { if (o.isSkinnedMesh) meshes.push(o); });
      for (const m of meshes) {
            const bones = m.skeleton.bones.map((b) => {
                  const bone = skeleton.getBoneByName(b.name);
                  if (!bone) throw new Error(`avatar has no bone "${b.name}"`);
                  return bone;
            });
            body.parent.add(m);                                           // same space as the body
            m.position.copy(body.position); m.quaternion.copy(body.quaternion); m.scale.copy(body.scale);
            m.updateMatrixWorld(true);
            m.bind(new THREE.Skeleton(bones, m.skeleton.boneInverses), m.bindMatrix);
            m.frustumCulled = false;
            wornMeshes.push(m);
      }
      setCover(outfit.cover);
      statusEl.textContent = '드래그: 회전 / 스크롤: 확대·축소';
}

// ---------------------------------------------------------------- pose sliders (bone-local axes, same as Blender)
const POSE = [
      { label: '왼팔 들기', bones: [['LeftArm', 'x', 1]], min: -40, max: 120 },
      { label: '오른팔 들기', bones: [['RightArm', 'x', 1]], min: -40, max: 120 },
      { label: '팔꿈치 굽힘', bones: [['LeftForeArm', 'z', -1], ['RightForeArm', 'z', 1]], min: 0, max: 130 },
      { label: '왼다리 앞으로', bones: [['LeftUpLeg', 'x', 1]], min: -30, max: 100 },
      { label: '다리 벌리기', bones: [['LeftUpLeg', 'z', 1], ['RightUpLeg', 'z', -1]], min: 0, max: 45 },
      { label: '무릎 굽힘', bones: [['LeftLeg', 'x', -1], ['RightLeg', 'x', -1]], min: 0, max: 130 },
      { label: '상체 숙이기', bones: [['Spine1', 'x', 1], ['Spine2', 'x', 1]], min: -20, max: 40 },
      { label: '고개 돌리기', bones: [['Neck', 'y', 1]], min: -60, max: 60 },
      { label: '주먹 쥐기', bones: ['Index', 'Middle', 'Ring', 'Pinky'].flatMap((f) => [1, 2, 3].flatMap((i) =>
            [[`LeftHand${f}${i}`, 'x', -1], [`RightHand${f}${i}`, 'x', -1]])), min: 0, max: 80 },
];
const restQ = new Map();
const values = POSE.map(() => 0);
function applyPose() {
      const acc = new Map();                                            // bone -> euler in degrees
      POSE.forEach((p, i) => p.bones.forEach(([name, axis, sign]) => {
            const e = acc.get(name) ?? { x: 0, y: 0, z: 0 }; e[axis] += sign * values[i]; acc.set(name, e);
      }));
      for (const [bone, q0] of restQ) {
            const e = acc.get(bone.name);
            bone.quaternion.copy(q0);
            if (e) bone.quaternion.multiply(new THREE.Quaternion().setFromEuler(
                  new THREE.Euler(THREE.MathUtils.degToRad(e.x), THREE.MathUtils.degToRad(e.y), THREE.MathUtils.degToRad(e.z), 'XYZ')));
      }
}
function buildUI() {
      const box = document.querySelector('#sliders');
      POSE.forEach((p, i) => {
            const l = document.createElement('label'); l.textContent = p.label;
            const s = document.createElement('input'); Object.assign(s, { type: 'range', min: p.min, max: p.max, value: 0 });
            s.addEventListener('input', () => { values[i] = +s.value; applyPose(); });
            box.append(l, s);
      });
      document.querySelector('#reset').onclick = () => {
            values.fill(0); box.querySelectorAll('input').forEach((s) => (s.value = 0)); applyPose();
      };
      const ob = document.querySelector('#outfits');
      for (const o of [{ id: '', label: '없음' }, ...outfits.map((o) => ({ ...o, label: o.label ?? o.id }))]) {
            const b = document.createElement('button'); b.textContent = o.label; b.dataset.id = o.id;
            b.onclick = () => wear(o.id ? o : null).catch(fail);
            ob.append(b);
      }
}

// ---------------------------------------------------------------- boot
function fail(e) { console.error(e); statusEl.textContent = '불러오기 실패 - 개발자 도구 console 확인'; }
(async () => {
      const manifest = await (await fetch(BASE + 'outfits.json')).json();
      outfits = manifest.outfits;
      const avatar = await loader.loadAsync(BASE + manifest.avatar);
      avatar.scene.traverse((o) => { if (o.isSkinnedMesh && !body) body = o; });
      skeleton = body.skeleton;
      skeleton.bones.forEach((b) => restQ.set(b, b.quaternion.clone()));
      body.frustumCulled = false;
      installCoverMask(body);
      scene.add(avatar.scene);
      buildUI();
      await wear(outfits[0] ?? null);
})().catch(fail);

addEventListener('resize', () => {
      camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix(); renderer.setSize(innerWidth, innerHeight);
});
renderer.setAnimationLoop(() => { controls.update(); renderer.render(scene, camera); });
