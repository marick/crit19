![](https://github.com/marick/crit19/blob/master/pics/1-trimmed.png?raw=true)


Around 2010, I wrote Critter4Us, an animal reservation system for the Agricultural Animal Care and Use Program of the University of Illinois School of Veterinary Medicine. It was a somewhat amateurish system - it was my first ever web application - but it continued to be used through 2019. At that time, I decided to write a better system, intending to open it up to other universities. Like the original, it would be free, because (1) my wife has been a professor of veterinary medicine for many years, so I feel affection for vet schools, (2) I'm (mostly) retired and everyone needs a hobby, right?

This is that better system.

Since I started, new management at the University of Illinois has they prefer an internally-developed system that will "link with several other programs and security features that the university already has in place." As a result, I'm slowing development on this version until I see if any other vet school is interested. 

### Features

* The system lets professors or administrators reserve teaching animals - much as they would reserve a meeting room.
* In addition, the system can prevent reservations that would violate animal care guidelines. 
* It also provides audit reports that shows guidelines have been followed. 
* The specific guidelines enforced are how often a particular procedure can be demonstrated on a particular animal. In the original Critter4Us, for example, paravertebral anesthesia could be demonstrated on a bovine only once every two weeks.
* The new system is being defined to be flexible. For example, sometimes professors use animals and only report that use after the fact. (Professors not following the rules? Who would have thought it!) Reservations can be created after the fact, even if they violated guidelines.
* The original system didn't have the notion of who gets billed for particular uses of particular animals. The new one doesn't either, but I expect I'll add it.

### Sample pages

I've tried to make the new version have the features of modern web apps (like scaling down nicely to fit on a phone screen). 

Here, someone is adding a reservation that already happened:
![](https://github.com/marick/crit19/blob/master/pics/2.png?raw=true)

Here's a form you'd use to mark an animal as out of service:
![](https://github.com/marick/crit19/blob/master/pics/3.png?raw=true)
