import { Controller } from "@hotwired/stimulus"

// Attach to a `<details>` element so it:
//   1. Closes when the user clicks anywhere outside of it.
//   2. Closes any other open <details> with this same controller when it opens
//      (so only one dropdown in a group is open at a time).
//
// Usage:
//   <details data-controller="dismissible-details" data-action="toggle->dismissible-details#enforceSingleOpen">
//     <summary>…</summary>
//     <div>…</div>
//   </details>
export default class extends Controller {
  static instances = new Set()

  connect() {
    this.constructor.instances.add(this)
    this.boundDocumentClick = this.handleDocumentClick.bind(this)
    document.addEventListener("click", this.boundDocumentClick)
  }

  disconnect() {
    this.constructor.instances.delete(this)
    document.removeEventListener("click", this.boundDocumentClick)
  }

  handleDocumentClick(event) {
    if (!this.element.open) return
    if (this.element.contains(event.target)) return
    this.element.open = false
  }

  // Wired via data-action="toggle->dismissible-details#enforceSingleOpen"
  enforceSingleOpen() {
    if (!this.element.open) return
    this.constructor.instances.forEach((instance) => {
      if (instance !== this && instance.element.open) {
        instance.element.open = false
      }
    })
  }
}
