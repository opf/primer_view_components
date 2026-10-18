// The parts of a form control's inline validation: the input it describes,
// the `.FormControl-inlineValidation` element, the message inside it and its
// two icons.
export interface InlineValidationParts {
  input: HTMLInputElement
  validation: HTMLElement
  message: HTMLElement
  successIcon: HTMLElement
  errorIcon: HTMLElement
}

export type InlineValidationKind = 'error' | 'success'

// The message is parsed as HTML, so callers must pass trusted markup.
export function renderValidationMessage(message: HTMLElement, html: string): void {
  const template = document.createElement('template')
  // eslint-disable-next-line github/no-inner-html
  template.innerHTML = html
  const fragment = document.importNode(template.content, true)
  message.replaceChildren(fragment)
}

// `invalid` is Primer's styling hook: "true" draws the danger border and
// "false" the success border. `aria-invalid` is only ever present as "true".
export function styleValidation(parts: InlineValidationParts, kind: InlineValidationKind): void {
  const isError = kind === 'error'

  parts.validation.classList.toggle('FormControl-inlineValidation--success', !isError)
  parts.successIcon.hidden = isError
  parts.errorIcon.hidden = !isError

  parts.input.setAttribute('invalid', isError ? 'true' : 'false')
  if (isError) {
    parts.input.setAttribute('aria-invalid', 'true')
  } else {
    parts.input.removeAttribute('aria-invalid')
  }
}

export function showValidation(parts: InlineValidationParts, html: string, kind: InlineValidationKind): void {
  styleValidation(parts, kind)
  renderValidationMessage(parts.message, html)
  parts.validation.hidden = false
}

export function clearValidation(parts: InlineValidationParts): void {
  parts.input.removeAttribute('invalid')
  parts.input.removeAttribute('aria-invalid')
  parts.validation.hidden = true
  parts.message.replaceChildren()
}
