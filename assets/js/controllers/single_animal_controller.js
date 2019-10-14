import { Controller } from "stimulus"


export default class extends Controller {
  connect() {
    this.load()
  }

  load() {
    fetch("/usables/animals/test")
      .then(response => response.text())
      .then(html => {
        this.element.innerHTML = html
      })
  }
}
