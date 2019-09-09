import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ "visibility" ];

    connect() {
        console.log("Hello, Stimulus!", this.element)
    }    
    namecheck(info) {
        console.log(info)
        console.log("key");
        if (info.key == "Enter") {
            console.log("ENTER");
            this.visibilityTarget.innerText = "hi"
        }
    }
}
