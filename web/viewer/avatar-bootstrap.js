const status = document.querySelector('#status');
let failed = false;

export function reportFailure() {
    if (failed) return;
    failed = true;
    status.hidden = false;
    status.style.display = 'flex';
    status.textContent = '아바타를 불러오지 못했습니다.';
    const retry = document.createElement('button');
    retry.type = 'button';
    retry.textContent = '다시 불러오기';
    retry.addEventListener('click', () => location.reload());
    status.appendChild(retry);
    parent.postMessage(
        { type: 'osee:avatar-viewer', state: 'error' },
        location.origin,
    );
    console.info('[OSEE_AVATAR] LOAD_FAILED');
}

// Dynamic import also handles a failure to download Three.js from the CDN.
import('./avatar.js').catch(reportFailure);
