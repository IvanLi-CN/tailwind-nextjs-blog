import { createRef } from 'preact'
import React, { useLayoutEffect, useMemo, useRef } from 'react'

interface DataAttributes {
  [key: string]: string | boolean | undefined
}

const insertScript = (
  src: string,
  id: string,
  dataAttributes: DataAttributes,
  onload = () => {}
) => {
  const script = window.document.createElement('script')
  script.async = true
  script.src = src
  script.id = id
  if (document.getElementById(id)) {
    return
  }
  script.addEventListener('load', onload, { capture: true, once: true })

  Object.entries(dataAttributes).forEach(([key, value]) => {
    if (value === undefined) {
      return
    }
    script.setAttribute(`data-${key}`, value.toString())
  })

  document.body.appendChild(script)

  return () => {
    script.remove()
  }
}

const ReactCommento = ({
  url,
  cssOverride,
  autoInit,
  noFonts,
  hideDeleted,
  pageId,
}: {
  url: string
  cssOverride?: string
  autoInit?: boolean
  noFonts?: boolean
  hideDeleted?: boolean
  pageId?: string
}) => {
  const containerId = useMemo(() => `commento-${Math.random().toString().slice(2, 8)}`, [])
  const container = createRef<HTMLDivElement>()

  useLayoutEffect(() => {
    if (!window) {
      return
    }

    window['commento'] = container.current

    const removeScript = insertScript(
      url,
      `${containerId}-script`,
      {
        'css-override': cssOverride,
        'auto-init': autoInit,
        'no-fonts': noFonts,
        'hide-deleted': hideDeleted,
        'page-id': pageId,
        'id-root': containerId,
      },
      () => {
        removeScript()
      }
    )
  }, [autoInit, cssOverride, hideDeleted, noFonts, pageId, url, containerId, container])

  return <div ref={container} id={containerId} />
}
export default ReactCommento
