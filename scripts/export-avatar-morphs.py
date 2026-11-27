"""Export private avatar files with Blender 4.5 to the ignored local viewer directory."""

import argparse
import csv
import json
import math
from pathlib import Path
import struct
import sys
import tempfile

import bpy


MEASUREMENTS = {
    '키': 'heightMm',
    '인심(가랑이~바닥)': 'inseamMm',
    '가슴 둘레': 'chestCircumferenceMm',
    '허리 둘레': 'waistCircumferenceMm',
    '엉덩이 둘레': 'hipCircumferenceMm',
    '허벅지 둘레': 'thighCircumferenceMm',
}
CONTROL_KEYS = {'Weight', 'Chest', 'Waist', 'Hips', 'Leg_Thickness', 'Leg_Length'}


def export_model(source, model, rows, output):
    bpy.ops.wm.open_mainfile(filepath=str(source), use_scripts=False)
    mesh = bpy.context.scene.objects.get('Avatar_Body')
    if mesh is None or mesh.type != 'MESH' or not mesh.data.shape_keys:
        raise ValueError(f'{model}: body mesh with shape keys required')
    keys = mesh.data.shape_keys.key_blocks
    basis = mesh.data.shape_keys.reference_key
    if not mesh.data.shape_keys.use_relative or any(
        keys.get(name) is None or keys[name].relative_key != basis
        or keys[name].value != 0 for name in CONTROL_KEYS
    ):
        raise ValueError(f'{model}: relative shape keys must start at zero')

    measurements = {}
    for row in rows:
        field = MEASUREMENTS.get(row['부위'])
        name = row['Shape Key 이름']
        if field is None or name not in CONTROL_KEYS:
            continue
        base, low, high = (
            float(row[column]) * 10 for column in (
                '기본형 치수(cm)', '줄였을 때 치수(cm)', '늘렸을 때 치수(cm)',
            )
        )
        lo = float(row['줄였을 때 키 값'])
        hi = float(row['늘렸을 때 키 값'])
        if not (all(math.isfinite(x) and x > 0 for x in (base, low, high))
                and keys[name].slider_min <= lo < 0 < hi <= keys[name].slider_max):
            raise ValueError(f'{model}: invalid calibration for {field}/{name}')
        measurement = measurements.setdefault(field, {'base': base, 'keys': {}})
        if measurement['base'] != base or name in measurement['keys']:
            raise ValueError(f'{model}: inconsistent calibration for {field}/{name}')
        measurement['keys'][name] = [lo, low - base, hi, high - base]
    primary = dict(zip(MEASUREMENTS.values(), (
        'Leg_Length', 'Leg_Length', 'Chest', 'Waist', 'Hips', 'Leg_Thickness',
    )))
    for field, name in primary.items():
        if name not in measurements.get(field, {}).get('keys', {}):
            raise ValueError(f'{model}: missing calibration for {field}/{name}')

    def vertical_bounds(shape_key, influence=1):
        low, high = math.inf, -math.inf
        for index, point in enumerate(shape_key.data):
            position = point.co if influence == 1 else basis.data[index].co.lerp(point.co, influence)
            y = (mesh.matrix_world @ position).z  # Blender Z becomes glTF Y.
            low, high = min(low, y), max(high, y)
        return low, high

    floor, top = vertical_bounds(basis)
    height = top - floor
    heights = measurements['heightMm']
    inseam = measurements['inseamMm']
    leg_range = inseam['keys']['Leg_Length']
    height_range = heights['keys']['Leg_Length']
    if leg_range[::2] != [-1, 1] or height_range[::2] != [-1, 1]:
        raise ValueError(f'{model}: unavailable leg length endpoints')
    leg_bounds = [vertical_bounds(keys['Leg_Length'], value) for value in (-1, 1)]
    armature = mesh.find_armature()
    if armature is None:
        raise ValueError(f'{model}: missing rig')
    ankles = [(armature.matrix_world @ armature.data.bones[name].head_local).z
              for name in ('LeftFoot', 'RightFoot')]
    ankle = sum(ankles) / len(ankles)

    # The supplied CSV measures to the floor, and the form measures to the ankle.
    def ankle_distance(ref_height, bounds):
        low, high = bounds
        if not low < ankle < high:
            raise ValueError(f'{model}: invalid ankle reference height')
        return ref_height * (ankle - low) / (high - low)

    baseline = ankle_distance(heights['base'], (floor, top))
    inseam['base'] -= baseline
    for i, bounds in zip((1, 3), leg_bounds):
        leg_range[i] += baseline - ankle_distance(heights['base'] + height_range[i], bounds)
    ratios = [(inseam['base'] + leg_range[i]) / (heights['base'] + height_range[i])
              for i in (1, 3)]
    if not 0 < ratios[0] < inseam['base'] / heights['base'] < ratios[1] < 1:
        raise ValueError(f'{model}: invalid inseam ratios')

    glb = output / f'{model}.glb'
    if bpy.ops.export_scene.gltf(
        filepath=str(glb), export_format='GLB', export_apply=False,
        export_animations=False, export_morph=True, export_morph_normal=True,
        export_morph_tangent=False,
    ) != {'FINISHED'}:
        raise ValueError(f'{model}: GLB export failed')
    with glb.open('rb') as handle:
        _, _, _, length, _ = struct.unpack('<4sIII4s', handle.read(20))
        exported = json.loads(handle.read(length))
    if not exported.get('skins') or not any(
        CONTROL_KEYS <= set(item.get('extras', {}).get('targetNames', []))
        for item in exported.get('meshes', [])
    ):
        raise ValueError(f'{model}: GLB lost its skin or morph targets')
    return {
        'measurements': measurements,
        'legFloorDeltas': [(low - floor) / height for low, _ in leg_bounds],
        'legTopDeltas': [(high - top) / height for _, high in leg_bounds],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for arg in ('male', 'female', 'measurements'):
        parser.add_argument(f'--{arg}', required=True, type=lambda p: Path(p).resolve(strict=True))
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    with args.measurements.open(encoding='utf-8-sig', newline='') as handle:
        rows = list(csv.DictReader(handle))
    output = Path(__file__).resolve().parents[1] / 'web/viewer/local-morphs'
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=output) as staging:
        staging = Path(staging)
        profiles = {
            model: export_model(getattr(args, model), model, (
                row for row in rows if row['성별'] == gender
            ), staging)
            for model, gender in (('male', '남성'), ('female', '여성'))
        }
        (staging / 'calibration.json').write_text(json.dumps(profiles), encoding='utf-8')
        for name in ('male.glb', 'female.glb', 'calibration.json'):
            (staging / name).replace(output / name)
    print('OSEE avatar morph assets exported to', output)


if __name__ == '__main__':
    main()
