import { Controller } from "@hotwired/stimulus"

// Wraps a password input + an eye-toggle button. Clicking the button swaps
// the input's `type` between "password" and "text", and swaps the visible
// icon between eye and eye-with-slash.
//
//   <div data-controller="password-toggle">
//     <input type="password" data-password-toggle-target="input" />
//     <button type="button" data-action="click->password-toggle#toggle">
//       <svg data-password-toggle-target="iconShow">…</svg>
//       <svg data-password-toggle-target="iconHide" class="hidden">…</svg>
//     </button>
//   </div>
export default class extends Controller {
  static targets = [ "input", "iconShow", "iconHide" ]

  toggle() {
    const wasHidden = this.inputTarget.type === "password"
    this.inputTarget.type = wasHidden ? "text" : "password"
    this.iconShowTarget.classList.toggle("hidden", wasHidden)
    this.iconHideTarget.classList.toggle("hidden", !wasHidden)
  }
}
