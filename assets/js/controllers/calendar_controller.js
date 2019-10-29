import { Controller } from "stimulus"
import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';


export default class extends Controller {
    static targets = [ "wrapper", "input", "div" ];

    reveal() {
        console.log(this.divTarget)

        this.calendar = new Calendar(this.divTarget, {
            plugins: [ dayGridPlugin, interactionPlugin ],
            defaultView: 'dayGridMonth'
        });
        console.log(this.wrapperTarget)
        this.wrapperTarget.classList.toggle("is-invisible", true)

        this.calendar.on('dateClick', (info) => {
            this.wrapperTarget.classList.toggle("is-invisible", false);
            this.inputTarget.value = info.dateStr;
            // this.calendar.select(info.date); -- replace if
            // we decide not to close the calendar on first click.
            this.calendar.destroy();
        })

        this.calendar.render();
    }
}
