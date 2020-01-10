import { Controller } from "stimulus"
import { formatISO } from 'date-fns'
import { parseISO } from 'date-fns'

export default class extends Controller {
    static targets = [ "hidden", "date" ];

    connect() {
        this.jquery_arg = this.data.get("jquery-arg");
        console.log("connected " + this.jquery_arg);

        this.calendar =
            jQuery(this.jquery_arg).calendar(
                {type: 'date',
                 formatInput: false,
                 onChange: () => { this.propagate_from_calendar() }
                });

        console.log("preparing to propagate from hidden");
        this.propagate_from_hidden();
    }

    propagate_from_calendar() {
        this.hiddenTarget.value = this.date_chosen();
        console.log(this.hiddenTarget);
        console.log(this.hiddenTarget.value);
    }

    propagate_from_hidden() { 
        console.log("hidden value starts as '" + this.hiddenTarget.value + "'");
        var hidden = this.hiddenTarget.value;
        if (hidden != "") {
            const date = parseISO(hidden);
            this.calendar.calendar('set date', date);
            console.log("date chosen is now " + this.date_chosen());
        }
    }

    date_chosen() {
        const date = jQuery(this.jquery_arg).calendar('get date');
        return formatISO(date, {representation: 'date'});
    }
}
