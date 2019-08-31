import { Controller } from "stimulus"
import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';


export default class extends Controller {
    static targets = [  ];

    connect() {
        console.log("calendar connected");
        var calendarEl = document.getElementById('calendar');

        this.calendar = new Calendar(calendarEl, {
            plugins: [ dayGridPlugin, interactionPlugin ],
            defaultView: 'dayGridMonth'
        });

        this.calendar.on('dateClick', (info) => {
            console.log('clicked on ' + info.dateStr);
            console.log(this.calendar);
            this.calendar.select(info.date);
        })

        this.calendar.render();
    }
}
