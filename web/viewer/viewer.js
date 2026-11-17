import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from "three/addons/controls/OrbitControls.js"

const status = document.querySelector("#status");

const scene = new THREE.Scene();
scene.background = new THREE.Color('#eeeae4');

const camera = new THREE.PerspectiveCamera(
      40,
      window.innerWidth / window.innerHeight,
      0.01,
      1000,
);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;

scene.add(new THREE.HemisphereLight(0xffffff, 0x777777, 2));

const light = new THREE.DirectionalLight(0xffffff, 3);
light.position.set(3, 5, 4);
scene.add(light)

// 두 모델의 상대적인 위치와 크기를 그대로 유지한다.
const character = new THREE.Group();
scene.add(character);

const loader = new GLTFLoader();

async function loadCharacter() {
      // Flutter 빌드 결과의 assets/modeling_glb 폴더를 가르킨다.
      const modelUrl = (name) =>
            new URL(`../assets/modeling_glb/${name}`, window.location.href).href;

      const [avatar, hoodie] = await Promise.all([
            loader.loadAsync(modelUrl('avatar.glb')),
            loader.loadAsync(modelUrl('hoodie.glb')),
      ]);

      character.add(avatar.scene, hoodie.scene);
      character.updateMatrixWorld(true)

      // 모델 전체 크기를 기준으로 카메라 위치를 맞춘다
      const box = new THREE.Box3().setFromObject(character);

      if(box.isEmpty()) {
            throw new Error("표시할 모델이 없습니다.");
      }

      const center = box.getCenter(new THREE.Vector3());
      const size = box.getSize(new THREE.Vector3());
      const radius = size.length() / 2;

      const verticalFov = THREE.MathUtils.degToRad(camera.fov);
      const horizontalFov = 2 * Math.atan(Math.tan(verticalFov / 2) * camera.aspect);
      const distance = radius / Math.sin(Math.min(verticalFov, horizontalFov) / 2) * 1.15;

      camera.position.set(center.x, center.y, center.z + distance);
      camera.near = Math.max(radius / 1000, 0.001);
      camera.far = distance + radius * 10;
      camera.updateProjectionMatrix();

      controls.target.copy(center);
      controls.update();

      status.textContent = "드래그: 회전 / 스크롤: 확대, 축소";
}

loadCharacter().catch((error) => {
      console.error(error);
      status.textContent = '모델 로딩 실패 - 개발 도구의 console 을 확인해주세요.';
});

window.addEventListener(`resize`, () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
});

renderer.setAnimationLoop(() => {
      controls.update();
      renderer.render(scene, camera);
});

