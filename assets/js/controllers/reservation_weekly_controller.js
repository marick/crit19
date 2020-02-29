import { Controller } from "stimulus"
import Calendar from 'tui-calendar'; /* ES6 */
import "tui-calendar/dist/tui-calendar.css";

// If you use the default popups, use this.
import 'tui-date-picker/dist/tui-date-picker.css';
import 'tui-time-picker/dist/tui-time-picker.css';

export default class extends Controller {

    connect() {
        this.load_week();
    }

    load_week() {
        fetch("/reservation/api/week_data")
            .then(response => response.text())
            .then(json => JSON.parse(json))
            .then(result => this.create_schedules(result));
    }

    create_schedules(result) {

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
            
        this.calendar = new Calendar('#calendar', {
            defaultView: 'week',
            template: templates,
            useDetailPopup: true,
            weekOptions: {hourStart: 6},
        });

        
        this.calendar.createSchedules(result["data"]);
    }
}
