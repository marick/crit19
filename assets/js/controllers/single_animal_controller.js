import { Controller } from "stimulus"


export default class extends Controller {
    connect() {
    }

    form() {
        var path = this.data.get("form-path");

        fetch(path)
            .then(response => response.text())
            .then(html => {
                this.element.innerHTML = html
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
        var form_id = this.data.get("form-id");
        // console.log("update path")
        // console.log(id)
        // console.log(path);

        const form = new FormData(document.getElementById(form_id));

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
