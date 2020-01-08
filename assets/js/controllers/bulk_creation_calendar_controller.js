import { Controller } from "stimulus"
import { formatISO } from 'date-fns'
import { parseISO } from 'date-fns'

export default class extends Controller {
    static targets = [ "hidden", "date", "radio" ];

    connect() {
        console.log("connected");
        this.calendar_id = this.data.get("calendar-id");
        this.radio_value = this.data.get("radio-value");

        this.calendar =
            jQuery(this.calendar_id).calendar(
                {type: 'date',
                 formatInput: false,
                 onChange: () => { this.propagate_from_calendar() }
                });

        this.propagate_from_hidden();
    }

    propagate_from_radio_button() {
        this.dateTarget.value = "";
        this.hiddenTarget.value = this.radio_value
        console.log(this.hiddenTarget.value);
    }        

    propagate_from_calendar() {
        this.radioTarget.checked = false;
        this.hiddenTarget.value = this.date_chosen();
        console.log(this.hiddenTarget.value);
    }

    propagate_from_hidden() { 
        console.log("hidden value starts as " + this.hiddenTarget.value);
        var hidden = this.hiddenTarget.value
        if (hidden == this.radio_value) {
            this.propagate_from_radio_button();
        }
        else {
            const date = parseISO(hidden);
            this.calendar.calendar('set date', date);
        }
    }

    date_chosen() {
        const date = jQuery(this.calendar_id).calendar('get date');
        return formatISO(date, {representation: 'date'});
    }
}
