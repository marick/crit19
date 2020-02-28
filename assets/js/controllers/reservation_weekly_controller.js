import { Controller } from "stimulus"
import Calendar from 'tui-calendar'; /* ES6 */
import "tui-calendar/dist/tui-calendar.css";

// If you use the default popups, use this.
import 'tui-date-picker/dist/tui-date-picker.css';
import 'tui-time-picker/dist/tui-time-picker.css';

export default class extends Controller {

    connect() {
        console.log("connected");

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
            
        var calendar = new Calendar('#calendar', {
            defaultView: 'week',
            template: templates,
            useDetailPopup: true,
            weekOptions: {hourStart: 6},
        });

        console.log(JSON.parse('{"id":"1", "calendarId": "1"}'))
        
        calendar.createSchedules([
            {
                id: '1',
                calendarId: '1',
                title: 'shipley',
                category: 'time',
                start: "2020-02-28T12:45:00",
                end: "2020-02-28T13:45:00",
                isReadOnly: true,
                body: "<p>Descriptive text</p><a href='http://exampleXt.com'>Click to edit or delete</a>"
            },
            {
                id: '2',
                calendarId: '2',
                title: 'dster',
                category: 'time',
                start: "2020-02-28T12:45:00",
                end: "2020-02-28T14:45:00",
                isReadOnly: true,
                body: "<p>Descriptive text</p><a href='http://exampleXt.com'>Click to edit or delete</a>"
            },


        ]);


        
        // calendar.on('clickSchedule', function(event) {
        //     var schedule = event.schedule;
        //     console.log(schedule);
        // });
    }
}
