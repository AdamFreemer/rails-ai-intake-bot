import { Controller } from "@hotwired/stimulus"

// Submits the form it's attached to after a brief debounce on `input` events,
// and immediately on `change` events (e.g. <select> dropdowns).
//
// Usage:
//   <%= form_with url: ..., method: :get,
//         data: { controller: "debounced-form",
//                 action: "input->debounced-form#submit change->debounced-form#submitNow",
//                 turbo_frame: "results" } do |f| %>
//
// Pair with <%= turbo_frame_tag "results" do %> around the results region so
// only the frame swaps rather than the whole page.
export default class extends Controller {
  static values = { delay: { type: Number, default: 250 } }

  disconnect() {
    clearTimeout(this.timeout)
  }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  submitNow() {
    clearTimeout(this.timeout)
    this.element.requestSubmit()
  }
}
