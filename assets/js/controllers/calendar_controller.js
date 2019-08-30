import { Controller } from "stimulus"
import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';


export default class extends Controller {
    static targets = [  ];

    connect() {
        console.log("calendar connected");
        var calendarEl = document.getElementById('calendar');

        var calendar = new Calendar(calendarEl, {
            plugins: [ dayGridPlugin ],
            defaultView: 'dayGridMonth'
        });

        calendar.render();
    }
}
