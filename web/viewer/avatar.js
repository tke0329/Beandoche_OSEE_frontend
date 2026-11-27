// Avatar-only 3D viewer, embedded in the Flutter fitting room as an iframe.
//
// Loads the female base avatar (beandoche_osee_modeling/Modeling_final/rig_woman.py -> modeling_glb/fitted/avatar_woman.glb),
// eases it from its A-pose rest into a relaxed stance, then keeps a subtle procedural idle
// (breathing, weight shift, head drift) so it reads as a person standing, not a statue.
// Query params:
//   ?model=female|male   base body (default female): Flutter asset modeling_glb/fitted/avatar_woman.glb / avatar.glb
//   ?src=<url>   avatar GLB, overrides ?model=
//   ?idle=0      disable the idle motion
// Posts {type:'osee:avatar-viewer', state:'ready'|'error'} to the parent window.
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { reportFailure } from './avatar-bootstrap.js';
import { heightTransform } from './avatar-height.js';
import { MAX_WIDTH_SCALE, widthScaleForWeight } from './avatar-weight.js';
import { solveMorphs } from './avatar-morphs.js';

async function start() {
    const params = new URLSearchParams(location.search);
    const MODELS = { female: 'avatar_woman.glb', male: 'avatar.glb' };
    const model = params.get('model') === 'male' ? 'male' : 'female';
    const localMorphs = params.get('morphs') === '1' && !params.has('src');
    const SRC =
        params.get('src') ??
        new URL(
            localMorphs
                ? `./local-morphs/${model}.glb`
                : `../assets/modeling_glb/fitted/${MODELS[model]}`,
            location.href,
        ).href;
    const IDLE =
        params.get('idle') !== '0' &&
        !matchMedia('(prefers-reduced-motion: reduce)').matches;
    const statusEl = document.querySelector('#status');
    const hintEl = document.querySelector('#hint');
    const notify = (state) =>
        parent?.postMessage(
            { type: 'osee:avatar-viewer', state },
            location.origin,
        );

    // ---------------------------------------------------------------- renderer / scene
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('webgl2', {
        antialias: true,
        alpha: true,
    });
    if (!context) {
        reportFailure();
        return;
    }
    const renderer = new THREE.WebGLRenderer({
        canvas,
        context,
        antialias: true,
        alpha: true,
    });
    renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    renderer.setClearColor(0x000000, 0); // transparent: the Flutter page shows through
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    document.body.appendChild(renderer.domElement);

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(28, 1, 0.01, 50);
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.enablePan = false;
    controls.minPolarAngle = Math.PI * 0.25; // no looking from straight above / below
    controls.maxPolarAngle = Math.PI * 0.55;

    scene.add(new THREE.HemisphereLight(0xffffff, 0xb9b2a8, 1.5));
    const key = new THREE.DirectionalLight(0xffffff, 2.0);
    key.position.set(1.5, 3.5, 2.5);
    scene.add(key);
    const rim = new THREE.DirectionalLight(0xffffff, 0.7);
    rim.position.set(-2.5, 2, -2.5);
    scene.add(rim);

    // pedestal: a low white disc (shadows are off for now)
    const PED_R = 0.46,
        PED_H = 0.03;
    const pedestal = new THREE.Group();
    const disc = new THREE.Mesh(
        new THREE.CylinderGeometry(PED_R, PED_R, PED_H, 96),
        new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.55 }),
    );
    disc.position.y = -PED_H / 2;
    const edge = new THREE.Mesh(
        new THREE.TorusGeometry(PED_R, 0.0022, 8, 128),
        new THREE.MeshBasicMaterial({ color: 0x9ca4b5 }),
    );
    edge.rotation.x = Math.PI / 2;
    const edgeLow = edge.clone();
    edgeLow.position.y = -PED_H;
    pedestal.add(disc, edge, edgeLow);
    pedestal.visible = false; // shown with the avatar, after framing
    scene.add(pedestal);

    function resize() {
        const w = innerWidth,
            h = innerHeight;
        renderer.setSize(w, h, false);
        camera.aspect = w / h;
        camera.updateProjectionMatrix();
    }
    addEventListener('resize', resize);
    resize();

    // ---------------------------------------------------------------- framing
    function frame(box) {
        box.union(new THREE.Box3().setFromObject(pedestal));
        const size = box.getSize(new THREE.Vector3());
        const center = box.getCenter(new THREE.Vector3());
        const vFov = THREE.MathUtils.degToRad(camera.fov);
        const hFov = 2 * Math.atan(Math.tan(vFov / 2) * camera.aspect);
        const dist =
            Math.max(
                (size.y * 1.16) / 2 / Math.tan(vFov / 2),
                (size.x * 1.1) / 2 / Math.tan(hFov / 2),
            ) +
            size.z / 2;
        controls.target.set(center.x, center.y, center.z);
        // slightly above eye level of the stage, so the pedestal reads as an ellipse
        camera.position.set(center.x, center.y + dist * 0.16, center.z + dist);
        camera.near = dist / 100;
        camera.far = dist * 10;
        camera.updateProjectionMatrix();
        controls.minDistance = dist * 0.4;
        controls.maxDistance = dist * 1.35;
        controls.update();
    }

    // ---------------------------------------------------------------- pose helpers
    // Bones follow Blender's convention: each bone points along its local +Y.
    const UP = new THREE.Vector3(0, 1, 0);
    const DOWN = new THREE.Vector3(0, -1, 0);
    const FORWARD = new THREE.Vector3(0, 0, 1); // the avatar faces +Z
    const X = new THREE.Vector3(1, 0, 0);
    const Y = UP;
    const Z = FORWARD;
    const _q = new THREE.Quaternion(),
        _p = new THREE.Quaternion(),
        _pi = new THREE.Quaternion();
    const _d = new THREE.Vector3(),
        _a = new THREE.Vector3();

    // Pose in avatar space so body width and depth do not skew bone rotations.
    function bodyQuaternion(object, out) {
        out.identity();
        for (let node = object; node && node !== bodyRoot; node = node.parent) {
            out.premultiply(node.quaternion);
        }
        return out;
    }

    /** Rotate `bone` by `angle` around an axis in avatar space. */
    function turn(bone, axis, angle) {
        if (!bone || !angle) return;
        bodyQuaternion(bone.parent, _p);
        _pi.copy(_p).invert();
        _q.setFromAxisAngle(axis, angle);
        bone.quaternion.premultiply(_p).premultiply(_q).premultiply(_pi);
        bone.updateMatrixWorld(true);
    }

    function direction(bone, out = _d) {
        return out
            .set(0, 1, 0)
            .applyQuaternion(bodyQuaternion(bone, _q))
            .normalize();
    }

    /** Swing `bone` by `angle` toward a world direction (negative swings away). */
    function tilt(bone, toward, angle) {
        if (!bone) return;
        const dir = direction(bone);
        _a.crossVectors(dir, toward);
        if (_a.lengthSq() < 1e-8) return;
        turn(bone, _a.normalize().clone(), angle);
    }

    /** Swing `bone` until it is `deg` degrees away from `toward`. */
    function aimWithin(bone, toward, deg) {
        if (!bone) return;
        const now = direction(bone).angleTo(toward);
        tilt(bone, toward, now - THREE.MathUtils.degToRad(deg));
    }

    // ---------------------------------------------------------------- avatar
    let rig = null; // { bones: name -> Bone, rest: Map, relaxed: Map, all: Bone[], root }
    let poseStart = 0;

    function buildRig(avatar) {
        const bones = {};
        avatar.traverse((o) => {
            if (o.isBone) bones[o.name] = o;
        });
        if (!bones.Hips || !bones.LeftArm || !bones.RightArm) return null;
        const all = Object.values(bones);
        const rest = new Map(all.map((b) => [b, b.quaternion.clone()]));
        avatar.updateMatrixWorld(true);

        // relaxed stance: arms hang close to the body, elbows soft, hands turned in
        for (const side of ['Left', 'Right']) {
            const out = side === 'Left' ? 1 : -1; // character's left is +X
            const lateral = new THREE.Vector3(out, 0, 0);
            tilt(bones[`${side}Shoulder`], DOWN, 0.1);
            aimWithin(bones[`${side}Arm`], DOWN, 16);
            tilt(bones[`${side}Arm`], FORWARD, 0.05);
            tilt(bones[`${side}ForeArm`], FORWARD, 0.2);
            tilt(bones[`${side}ForeArm`], lateral, -0.06);
            tilt(bones[`${side}Hand`], lateral, -0.12);
            // a natural finger curl: each joint folds a little toward the palm (forward / inward)
            for (const f of ['Index', 'Middle', 'Ring', 'Pinky']) {
                for (let j = 1; j <= 3; j++) {
                    const bone = bones[`${side}Hand${f}${j}`];
                    if (!bone) continue;
                    const palm = new THREE.Vector3(-out, 0, 0.6).normalize();
                    tilt(bone, palm, j === 1 ? 0.14 : 0.24);
                }
            }
            tilt(bones[`${side}HandThumb1`], FORWARD, 0.15);
            tilt(
                bones[`${side}HandThumb2`],
                new THREE.Vector3(-out, 0, 0),
                0.15,
            );
        }
        // feet a touch apart and toes slightly out reads less "mannequin"
        turn(bones.LeftUpLeg, Y, 0.06);
        turn(bones.RightUpLeg, Y, -0.06);

        const relaxed = new Map(all.map((b) => [b, b.quaternion.clone()]));
        // restore the rest pose; the render loop eases into the relaxed one
        for (const b of all) b.quaternion.copy(rest.get(b));
        avatar.updateMatrixWorld(true);
        // parents first, so world-space idle turns compose correctly
        all.sort((a, b) => depth(a) - depth(b));
        return { bones, rest, relaxed, all, root: avatar };
    }

    function depth(o) {
        let d = 0;
        while (o.parent) {
            d++;
            o = o.parent;
        }
        return d;
    }

    const ease = (k) => (k >= 1 ? 1 : 1 - Math.pow(1 - k, 3));
    const wave = (t, period, phase = 0) =>
        Math.sin((2 * Math.PI * t) / period + phase);

    function animate(t) {
        if (!rig) return;
        const { bones: b, rest, relaxed, all, root } = rig;
        const k = ease((t - poseStart) / 1.1);
        for (const bone of all)
            bone.quaternion.slerpQuaternions(
                rest.get(bone),
                relaxed.get(bone),
                k,
            );
        root.updateMatrixWorld(true);
        if (!IDLE) return;

        const breathe = wave(t, 4.4);
        const sway = wave(t, 8.5);
        const drift = wave(t, 11, 1.3);

        // weight shift: pelvis rocks, spine counters, legs stay planted
        turn(b.Hips, Z, 0.016 * sway);
        turn(b.Hips, Y, 0.022 * drift);
        turn(b.LeftUpLeg, Z, -0.016 * sway);
        turn(b.RightUpLeg, Z, -0.016 * sway);
        turn(b.LeftUpLeg, Y, -0.022 * drift);
        turn(b.RightUpLeg, Y, -0.022 * drift);
        turn(b.Spine, Z, -0.022 * sway);
        turn(b.Spine1, Y, -0.012 * drift);

        // breathing: chest lifts and opens, shoulders rise a little
        turn(b.Spine1, X, -0.01 * breathe);
        turn(b.Spine2, X, -0.012 * breathe);
        tilt(b.LeftShoulder, UP, (0.012 * (breathe + 1)) / 2);
        tilt(b.RightShoulder, UP, (0.012 * (breathe + 1)) / 2);

        // head: slow look-around and a level horizon against the sway
        turn(b.Neck, Y, 0.06 * wave(t, 9.5, 0.7));
        turn(b.Head, X, 0.018 * wave(t, 6.7, 2.1));
        turn(b.Head, Z, 0.014 * sway);

        // arms hang and swing very slightly with the body
        for (const [side, ph] of [
            ['Left', 0],
            ['Right', 1.7],
        ]) {
            tilt(b[`${side}Arm`], FORWARD, 0.025 * wave(t, 8.5, ph));
            tilt(b[`${side}ForeArm`], FORWARD, 0.03 * breathe);
        }
    }

    const clock = new THREE.Clock();
    const [gltf, calibration] = await Promise.all([
        new GLTFLoader().loadAsync(SRC),
        localMorphs
            ? fetch('./local-morphs/calibration.json').then(
                  async (response) => {
                      if (!response.ok)
                          throw new Error('Missing avatar calibration');
                      return (await response.json())[model];
                  },
              )
            : null,
    ]);
    if (localMorphs && !calibration)
        throw new Error('Missing model calibration');
    const avatar = gltf.scene;
    const morphMeshes = [];
    avatar.traverse((o) => {
        if (o.isMesh) o.frustumCulled = false;
        if (o.morphTargetDictionary) morphMeshes.push(o);
    });
    const bodyRoot = new THREE.Group();
    bodyRoot.add(avatar);
    scene.add(bodyRoot);
    const baseBounds = new THREE.Box3().setFromObject(avatar);
    const baseHeight = baseBounds.max.y - baseBounds.min.y;
    // Fit the camera to a common height so zoom does not cancel out body scaling.
    const PREVIEW_FRAME_HEIGHT = 2.2;
    let frameHeight;
    function frameBody() {
        const frameWidthScale = (frameHeight / baseHeight) * MAX_WIDTH_SCALE;
        const bounds = baseBounds.clone();
        bounds.min.multiplyScalar(frameWidthScale);
        bounds.max.multiplyScalar(frameWidthScale);
        bounds.min.y = 0;
        bounds.max.y = frameHeight;
        frame(bounds);
    }
    rig = buildRig(avatar);
    poseStart = clock.getElapsedTime();
    const heightLabel = document.querySelector('#height');
    const weightLabel = document.querySelector('#weight');
    const rangeLabel = document.querySelector('#range');
    function applyMeasurements(heightMm, weightKg, dimensions = {}) {
        let targetHeight = heightMm;
        let width = 1;
        if (calibration) {
            const morph = solveMorphs(
                calibration,
                heightMm,
                weightKg,
                dimensions,
            );
            targetHeight = morph.height;
            for (const [key, value] of Object.entries(morph.influences)) {
                const meshes = morphMeshes.filter(
                    (mesh) => key in mesh.morphTargetDictionary,
                );
                if (meshes.length === 0)
                    throw new Error('Missing avatar morph target');
                for (const mesh of meshes) {
                    mesh.morphTargetInfluences[
                        mesh.morphTargetDictionary[key]
                    ] = value;
                }
            }
            rangeLabel.hidden = !morph.limited;
        } else {
            width = widthScaleForWeight(weightKg);
        }
        const transform = heightTransform(
            baseBounds.min.y,
            baseHeight,
            targetHeight,
        );
        const widthScale = transform.scale * width;
        bodyRoot.scale.set(widthScale, transform.scale, widthScale);
        bodyRoot.position.y = transform.offsetY;
        bodyRoot.updateMatrixWorld(true);
        const nextFrameHeight =
            targetHeight === null
                ? baseHeight
                : Math.max(PREVIEW_FRAME_HEIGHT, targetHeight / 1000);
        if (nextFrameHeight !== frameHeight) {
            frameHeight = nextFrameHeight;
            frameBody();
        }
        heightLabel.textContent =
            heightMm === null ? '' : `키 ${heightMm / 10} cm`;
        weightLabel.textContent =
            weightKg === null ? '' : `몸무게 ${weightKg} kg`;
    }
    applyMeasurements(null, null);
    addEventListener('message', (event) => {
        if (
            event.origin !== location.origin ||
            event.source !== parent ||
            event.data?.type !== 'osee:avatar-config'
        )
            return;
        try {
            applyMeasurements(
                event.data.heightMm,
                event.data.weightKg ?? null,
                event.data.dimensionsMm,
            );
        } catch {
            renderer.setAnimationLoop(null);
            reportFailure();
        }
    });
    pedestal.visible = true;
    addEventListener('resize', frameBody);
    statusEl.hidden = true;
    statusEl.style.display = 'none';
    hintEl.style.opacity = '1';
    setTimeout(() => (hintEl.style.opacity = '0'), 3500);
    notify('ready');

    renderer.setAnimationLoop(() => {
        try {
            animate(clock.getElapsedTime());
            controls.update();
            renderer.render(scene, camera);
        } catch {
            renderer.setAnimationLoop(null);
            reportFailure();
        }
    });
    renderer.domElement.addEventListener('webglcontextlost', () => {
        renderer.setAnimationLoop(null);
        reportFailure();
    });
}

start().catch(reportFailure);
