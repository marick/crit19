import { Controller } from "stimulus"


export default class extends Controller {
    static targets = [ "date", "radio" ];

    connect() {
    }

    reveal() {
        const calendar_id = this.data.get("calendar-id");
        jQuery(calendar_id).calendar(
            {type: 'date',
             onChange: () => {
                 this.radioTarget.checked = false;
                 return true;
             }});
        jQuery(calendar_id).calendar("popup", "show");
    }

    pick_default() {
        console.log("pick default");
        this.dateTarget.value = "";
    }
    
            
}
