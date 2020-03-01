import { Controller } from "stimulus"
import Calendar from 'tui-calendar'; /* ES6 */
import "tui-calendar/dist/tui-calendar.css";

// // If you use the default popups, use this.
// import 'tui-date-picker/dist/tui-date-picker.css';
// import 'tui-time-picker/dist/tui-time-picker.css';

export default class extends Controller {
    static targets = ["context", "dimmer"];

    connect() {
        this.first_calendar();
        this.today();
    }

    first_calendar() {
        const templates = {
            popupDetailBody: function(schedule) {
                return schedule.body;
            },
            popupEdit: function() {
                return "";
            },
            popupDelete: function() {
                return "";
            }
        };

        const theme_overrides = { 
            'week.timegridOneHour.height': '24px',
            'week.timegridHalfHour.height': '12px',
        };
    
        
        this.calendar = new Calendar('#calendar', {
            defaultView: 'week',
            template: templates,
            useDetailPopup: true,
            taskView: false,
            week: {hourStart: 7},
            theme: theme_overrides,
        });
    }

    load_week() {
        // this.dimmerTarget.classList.toggle("active");
        fetch("/reservation/api/week_data/" + this.week_offset)
            .then(response => response.text())
            .then(json => JSON.parse(json))
            .then(result => this.create_schedules(result));
    }

    create_schedules(result) {
        this.calendar.clear();
        this.calendar.createSchedules(result["data"]);
        this.calendar.render();

        this.contextTarget.innerHTML = this.context_message();
        // this.dimmerTarget.classList.toggle("active");
    }

    context_message() {
        const date = this.calendar.getDate().toDate();
        const options = {year: 'numeric', month: 'long'};
        const date_string = date.toLocaleDateString(undefined, options);
        return "A week in " + date_string;
    }

    today() { 
        this.calendar.today();
        this.week_offset = 0;
        this.load_week();
    }

    previous_week() {
        this.calendar.prev();
        this.week_offset--;
        this.load_week();
    }

    next_week() {
        this.calendar.next();
        this.week_offset++;
        this.load_week();
    }
}
