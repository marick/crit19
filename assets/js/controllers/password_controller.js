import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ "field" ];
    
    toggle_visibility() {
        this.fieldTargets.map(this.toggle);
    }

    toggle(field) {     
        if (field.type == "password") {
            field.type = "text";
        } else {
            field.type = "password";
        }
    }

}
