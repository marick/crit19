import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ "password" ];
    
    toggle() {
        const element = this.passwordTarget;

        if (element.type == "password") {
            element.type = "text";
        } else {
            element.type = "password";
        }
                
    }
}
