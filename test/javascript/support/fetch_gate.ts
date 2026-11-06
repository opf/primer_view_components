// A controllable fetch for unit tests: every request is held until the test
// releases it, so tests decide the order in which responses arrive.
// Requests are keyed by pathname + search, attempts are 1-based per key.

type Pending = {resolve: (response: Response) => void}
type ReleaseOptions = {status?: number; body?: string; attempt?: number}

export type FetchGate = {
  install(): void
  restore(): void
  started(url: string, attempt?: number): Promise<void>
  release(url: string, opts?: ReleaseOptions): void
  count(url: string): number
}

const keyOf = (input: RequestInfo | URL): string => {
  const href = input instanceof Request ? input.url : String(input)
  const url = new URL(href, 'http://localhost')
  return `${url.pathname}${url.search}`
}

export function createFetchGate(): FetchGate {
  const requests = new Map<string, Pending[]>()
  const waiters: Array<() => void> = []
  let original: typeof fetch | undefined

  const notify = () => {
    for (const waiter of waiters.splice(0)) waiter()
  }

  const gatedFetch = (input: RequestInfo | URL): Promise<Response> =>
    new Promise(resolve => {
      const key = keyOf(input)
      requests.set(key, [...(requests.get(key) ?? []), {resolve}])
      notify()
    })

  const count = (url: string) => requests.get(keyOf(url))?.length ?? 0

  return {
    install() {
      original = globalThis.fetch
      globalThis.fetch = gatedFetch as typeof fetch
    },
    restore() {
      if (original) globalThis.fetch = original
    },
    count,
    started(url, attempt = 1) {
      return new Promise((resolve, reject) => {
        const check = () => {
          if (count(url) >= attempt) {
            clearTimeout(timer)
            resolve()
          } else {
            waiters.push(check)
          }
        }
        const timer = setTimeout(() => reject(new Error(`request ${url} (attempt ${attempt}) never started`)), 1000)
        check()
      })
    },
    release(url, {status = 200, body = '', attempt = 1} = {}) {
      const pending = requests.get(keyOf(url))?.[attempt - 1]
      if (!pending) throw new Error(`no request ${url} (attempt ${attempt}) to release`)
      pending.resolve(new Response(body, {status, headers: {'Content-Type': 'text/html'}}))
    },
  }
}

// Lets upstream's task-queued events and the resolved fetch chains settle
export async function flush(): Promise<void> {
  for (let i = 0; i < 3; i++) await new Promise(resolve => setTimeout(resolve, 0))
}
