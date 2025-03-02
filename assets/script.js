document.addEventListener("DOMContentLoaded", function () {
    const scrollContainer = document.querySelector(".scrollable-list");

    scrollContainer.addEventListener("wheel", function (event) {
        event.preventDefault();
        scrollContainer.scrollBy({
            top: event.deltaY, // Przewijanie w pionie
            behavior: "smooth" // Płynne przewijanie
        });
    });
});
