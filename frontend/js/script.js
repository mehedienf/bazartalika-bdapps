/* ===========================================================
 * Bazar Talika — landing page interactions
 * Pure vanilla JS: smooth scroll, mobile nav, theme & language
 * toggles, scroll-reveal animations, dynamic year.
 * =========================================================== */

(function () {
  'use strict';

  /* ---------- 1. Dynamic year in footer ---------- */
  const yearEl = document.getElementById('year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  /* ---------- 2. Smooth scroll for in-page anchors ---------- */
  const anchors = document.querySelectorAll('a[href^="#"]');
  anchors.forEach((a) => {
    a.addEventListener('click', (e) => {
      const id = a.getAttribute('href');
      if (!id || id === '#') return;
      const target = document.querySelector(id);
      if (!target) return;
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      // close mobile menu after navigation
      closeMobileMenu();
    });
  });

  /* ---------- 3. Navbar shadow on scroll ---------- */
  const navbar = document.getElementById('navbar');
  const onScroll = () => {
    if (!navbar) return;
    if (window.scrollY > 8) navbar.classList.add('scrolled');
    else navbar.classList.remove('scrolled');
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  /* ---------- 4. Mobile hamburger menu ---------- */
  const hamburger = document.getElementById('hamburger');
  const navLinks = document.getElementById('navLinks');

  function closeMobileMenu() {
    if (!hamburger || !navLinks) return;
    navLinks.classList.remove('open');
    hamburger.classList.remove('open');
    hamburger.setAttribute('aria-expanded', 'false');
  }

  if (hamburger && navLinks) {
    hamburger.addEventListener('click', () => {
      const isOpen = navLinks.classList.toggle('open');
      hamburger.classList.toggle('open', isOpen);
      hamburger.setAttribute('aria-expanded', String(isOpen));
    });
  }

  /* ---------- 5. Theme toggle (light / dark) ---------- */
  const themeBtn = document.getElementById('themeToggle');
  const root = document.documentElement;
  const THEME_KEY = 'bt-theme';

  function applyTheme(theme) {
    if (theme === 'dark') root.setAttribute('data-theme', 'dark');
    else root.removeAttribute('data-theme');
  }

  const savedTheme = localStorage.getItem(THEME_KEY);
  if (savedTheme) applyTheme(savedTheme);

  if (themeBtn) {
    themeBtn.addEventListener('click', () => {
      const current = root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
      const next = current === 'dark' ? 'light' : 'dark';
      applyTheme(next);
      localStorage.setItem(THEME_KEY, next);
      themeBtn.setAttribute('aria-label',
        next === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
    });
  }

  /* ---------- 6. Language toggle (BN <-> EN) ---------- */
  const langBtn = document.getElementById('langToggle');
  const langLabel = document.getElementById('langLabel');
  const LANG_KEY = 'bt-lang';

  const I18N = {
    bn: {
      navFeatures: 'ফিচার', navHow: 'কীভাবে কাজ করে', navScreens: 'স্ক্রিনশট',
      navDownload: 'ডাউনলোড', navContact: 'যোগাযোগ',
      heroBadge: '📱 বাংলাদেশের জন্য তৈরি',
      heroTitle1: 'বাজারের তালিকা এখন',
      heroTitle2: 'একদম সহজ',
      heroSub: 'বাজার তালিকা অ্যাপ দিয়ে আপনার প্রতিদিনের কেনাকাটার তালিকা দ্রুত তৈরি করুন, দাম হিসাব রাখুন এবং পরিবারের সাথে এক ক্লিকে শেয়ার করুন।',
      heroCta1: 'অ্যাপ ডাউনলোড', heroCta2: 'ফিচার দেখুন →',
      statFree: 'ফ্রি', statDark: 'ডার্ক মোড', statShare: 'শেয়ার', statArchive: 'আর্কাইভ',
      langCode: 'EN',
    },
    en: {
      navFeatures: 'Features', navHow: 'How it works', navScreens: 'Screenshots',
      navDownload: 'Download', navContact: 'Contact',
      heroBadge: '📱 Built for Bangladesh',
      heroTitle1: 'Your shopping list,',
      heroTitle2: 'made simple',
      heroSub: 'Create daily grocery lists in seconds, track prices, and share them with your family in one tap.',
      heroCta1: 'Download App', heroCta2: 'See features →',
      statFree: 'Free', statDark: 'Dark Mode', statShare: 'Share', statArchive: 'Archive',
      langCode: 'BN',
    },
  };

  function applyLang(lang) {
    const dict = I18N[lang] || I18N.bn;
    document.documentElement.setAttribute('lang', lang === 'en' ? 'en' : 'bn');
    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      if (dict[key] !== undefined) el.textContent = dict[key];
    });
    if (langLabel) langLabel.textContent = dict.langCode;
  }

  const savedLang = localStorage.getItem(LANG_KEY);
  if (savedLang && I18N[savedLang]) applyLang(savedLang);

  if (langBtn) {
    langBtn.addEventListener('click', () => {
      const current = localStorage.getItem(LANG_KEY) || 'bn';
      const next = current === 'bn' ? 'en' : 'bn';
      applyLang(next);
      localStorage.setItem(LANG_KEY, next);
    });
  }

  /* ---------- 7. Scroll-reveal animations ---------- */
  const revealEls = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window && revealEls.length) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    revealEls.forEach((el) => io.observe(el));
  } else {
    revealEls.forEach((el) => el.classList.add('visible'));
  }

  /* ---------- 8. Click-to-copy for download links (placeholder APK) ---------- */
  document.querySelectorAll('[data-copy]').forEach((btn) => {
    btn.addEventListener('click', async (e) => {
      const text = btn.getAttribute('data-copy');
      if (!text) return;
      try {
        await navigator.clipboard.writeText(text);
        const original = btn.dataset.label || btn.textContent;
        btn.dataset.label = original;
        btn.textContent = '✓ Copied';
        setTimeout(() => { btn.textContent = original; }, 1400);
      } catch (err) {
        // clipboard not available — silently ignore
      }
    });
  });
})();
