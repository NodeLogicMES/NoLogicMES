let currentLang = localStorage.getItem('nologic_lang') || 'en';

async function loadLang(lang) {
    try {
        const result = await fetch(`/static/langs/${lang}.json`);
        if (!result.ok) throw new Error(`No se encontró el idioma: ${lang}`);
        
        const dict = await result.json();
        document.querySelectorAll('[data-i18n]').forEach(element => {
            const key = element.getAttribute('data-i18n');
            if (dict[key]) {
                element.textContent = dict[key];
                const width = dict[key].length * 9.5
                element.parentElement.setAttribute("viewBox", `0 0 ${width} ${width}`) 
            }
        });
        localStorage.setItem('nologic_lang', lang);
        document.documentElement.lang = lang;

    } catch (error) {
        console.error("Error loading translations:", error);
    }
}

function changeLang(newLang) {
    loadLang(newLang);
}

document.addEventListener('DOMContentLoaded', () => {
    loadLang(currentLang);
});