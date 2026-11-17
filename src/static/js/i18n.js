// Idioma por defecto: el guardado en el navegador o 'es'
let idiomaActual = localStorage.getItem('nologic_lang') || 'es';

async function cargarIdioma(lang) {
    try {
        // 1. Descargamos el archivo JSON del idioma
        const respuesta = await fetch(`/static/langs/${lang}.json`);
        if (!respuesta.ok) throw new Error(`No se encontró el idioma: ${lang}`);
        
        const diccionario = await respuesta.json();

        // 2. Buscamos todos los elementos HTML que tengan el atributo data-i18n
        document.querySelectorAll('[data-i18n]').forEach(elemento => {
            const clave = elemento.getAttribute('data-i18n');
            if (diccionario[clave]) {
                elemento.textContent = diccionario[clave];
            }
        });

        // 3. Guardamos la preferencia y actualizamos la etiqueta <html>
        localStorage.setItem('nologic_lang', lang);
        document.documentElement.lang = lang;

    } catch (error) {
        console.error("Error cargando traducciones:", error);
    }
}

// Función para los botones de cambio de idioma
function cambiarIdioma(nuevoLang) {
    cargarIdioma(nuevoLang);
}

// Ejecutar automáticamente al cargar cualquier página
document.addEventListener('DOMContentLoaded', () => {
    cargarIdioma(idiomaActual);
});