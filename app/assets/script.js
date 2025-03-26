function enableSmoothScrolling() {
    const scrollContainer = document.querySelector(".scrollable-list");

    if (!scrollContainer) return;

    scrollContainer.addEventListener("wheel", function (event) {
        event.preventDefault();
        scrollContainer.scrollBy({
            top: event.deltaY,
            behavior: "smooth"
        });
    });
}

document.addEventListener("DOMContentLoaded", enableSmoothScrolling);
