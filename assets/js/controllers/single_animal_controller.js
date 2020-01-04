import { Controller } from "stimulus"


export default class extends Controller {
    connect() {
    }


    form() {
        var path = this.data.get("form-path");
        var id = this.data.get("id");
        var element = document.getElementById(this.data.get("id"));

        const config = { attributes: true, childList: true, subtree: true };


        const observer = new MutationObserver((_mutations_list, observer) => {
            console.log(this.element);
            console.log(this.element.innerHTML);
            console.log("cal1_editing_animal" + id);
            
            const calendar = document.getElementById("cal1_" + id);
            console.log(calendar);
            console.log(jQuery("cal1_" + id));

            console.log(jQuery("#standard_calendar").calendar());
            console.log(jQuery("#cal1_" + id).calendar());
            console.log("dine");
            observer.disconnect();
        });

        observer.observe(this.element, config);        
        
        
        fetch(path)
            .then(response => response.text())
            .then(html => {
                this.element.innerHTML = html
                console.log(this.element.innerHTML);
            })
    }

    cancel(event) {
        event.preventDefault();
        var path = this.data.get("cancel-path");
        
        var result = fetch(path)
            .then(response => response.text())
            .then(html => {
                this.element.innerHTML = html;
            });
    }

    update(event) {
        event.preventDefault();
        var path = this.data.get("update-path");
        var id = this.data.get("id");
        // console.log("update path")
        // console.log(id)
        // console.log(path);

        const form = new FormData(document.getElementById(id));

        var data = {
            method: 'POST',
            cache: 'no-cache',
            credentials: 'same-origin',
            body: form
        }

        var result = fetch(path, data)
            .then(response => response.text())
            .then(html => {
                this.element.innerHTML = html
            })
    }
}
