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
        const local_offset =
              this.browser_timezone_offset(new Date().getTimezoneOffset());
        const locally_timed_schedules = 
              this.convert_to_browser_datetime(result["data"], local_offset)
        
        this.calendar.clear();
        this.calendar.createSchedules(locally_timed_schedules);
        this.calendar.render();

        this.contextTarget.innerHTML = this.context_message();
    }

    convert_to_browser_datetime(schedules, offset_suffix) {
        return schedules.map(function(elt) {
            elt.start = elt.start + offset_suffix;
            elt.end = elt.end  +  offset_suffix;
            return elt;
        })
    }


    // Critter4Us always works in timezone-less times (Elixir
    // `NaiveDateTime`).  Toast Calendar takes the browser's local
    // timezone into account. To have it show the intended time *as
    // seen from the institution's timezone*, we have to add the local
    // timezone's offset to the string representations of time. 
    //
    // It appears that non-Safari browsers do this automatically when
    // given a timezone-free ISO8601(ish) time representation, but
    // wotthehell archie wotthehell 
    
    browser_timezone_offset(minute_offset) {
        const offset_string = (minute_offset / -60).toString()

        var sign;
        var hours;

        if (offset_string.includes(".")) {
            throw "Critter4Us doesn't work in timezones a fractional hour away from UTC";
        }

        if (offset_string.slice(0, 1) == "-") {
            sign = "-";
            hours = offset_string.slice(1);
        } else {
            sign = "+";
            hours = offset_string;
        }

        if (hours.length == 1) {
            hours = "0" + hours;
        }

        return sign + hours + ":00";
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
