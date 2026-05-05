'use strict';

const panel      = document.getElementById('breathalyzer');
const bacValue   = document.getElementById('bac-value');
const statusText = document.getElementById('status-text');
const overlay    = document.getElementById('screen-overlay');
const suspectEl  = document.getElementById('suspect-name');

let hideTimer  = null;
let animFrame  = null;

function beep() {
    try {
        const ctx  = new (window.AudioContext || window.webkitAudioContext)();
        const osc  = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type            = 'square';
        osc.frequency.value = 880;
        gain.gain.setValueAtTime(0.3, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.18);
        osc.start(ctx.currentTime);
        osc.stop(ctx.currentTime + 0.18);
    } catch (e) {}
}

function animateCountUp(target, duration) {
    const start = performance.now();
    if (animFrame) cancelAnimationFrame(animFrame);

    function tick(now) {
        const t       = Math.min((now - start) / duration, 1);
        const eased   = 1 - Math.pow(1 - t, 3);
        const current = target * eased;
        bacValue.textContent = current.toFixed(3);
        if (t < 1) {
            animFrame = requestAnimationFrame(tick);
        } else {
            bacValue.textContent = target.toFixed(3);
        }
    }

    animFrame = requestAnimationFrame(tick);
}

function showResult(data) {
    if (hideTimer)  { clearTimeout(hideTimer);         hideTimer  = null; }
    if (animFrame)  { cancelAnimationFrame(animFrame); animFrame  = null; }

    const bac       = parseFloat(data.bac) || 0;
    const overLimit = data.overLimit === true;

    suspectEl.textContent  = data.suspectName || '---';

    // reset state
    bacValue.textContent   = '0.000';
    bacValue.className     = '';
    statusText.textContent = 'READING...';
    statusText.className   = 'status-text';
    overlay.className      = 'screen-overlay';

    panel.classList.remove('hidden', 'hiding');

    animateCountUp(bac, 1900);

    // beep just before verdict, then show result
    setTimeout(() => beep(), 1850);

    setTimeout(() => {
        if (overLimit) {
            bacValue.classList.add('over');
            statusText.textContent = 'OVER LIMIT';
            statusText.classList.add('over');
            overlay.classList.add('over');
        } else {
            bacValue.classList.add('clear');
            statusText.textContent = 'CLEAR';
            statusText.classList.add('clear');
            overlay.classList.add('clear');
        }
    }, 2000);

    hideTimer = setTimeout(hide, 8000);
}

function hide() {
    if (animFrame) { cancelAnimationFrame(animFrame); animFrame = null; }
    panel.classList.add('hiding');
    setTimeout(() => panel.classList.add('hidden'), 340);
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.type) return;
    if (data.type === 'kg-alcolizer:showResult') showResult(data);
    else if (data.type === 'kg-alcolizer:hide')  hide();
});
