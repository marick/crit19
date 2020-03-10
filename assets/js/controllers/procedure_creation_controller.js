import { Controller } from "stimulus"


export default class extends Controller {
    static targets = [ "checkboxes" ];
    
    connect() {
    }

    put_one_checkbox_column(event) {
        const template = event.target;

        const subset = this.checkboxesTargets.filter((elt) => {
            return elt.value == template.value;
        })

        console.log(subset);

        subset.forEach((elt) => {
            elt.checked = template.checked;
        });
    }

}
