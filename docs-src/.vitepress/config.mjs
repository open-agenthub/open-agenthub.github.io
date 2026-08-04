import { defineConfig } from 'vitepress'

// The site is served from the landing-page repository at /docs/, and GitHub Pages
// deploys that repo straight from the branch root — so this build writes its output
// into ../docs and that directory is committed.
export default defineConfig({
  title: 'Open AgentHub',
  description: 'Run and control coding agents in Kubernetes.',
  lang: 'en-US',
  base: '/docs/',
  outDir: '../docs',
  cleanUrls: true,
  lastUpdated: true,
  head: [['link', { rel: 'icon', href: '/favicon.svg' }]],
  themeConfig: {
    siteTitle: 'Open AgentHub docs',
    nav: [
      { text: 'Guide', link: '/getting-started' },
      { text: 'Landing page', link: 'https://open-agenthub.github.io/' },
      { text: 'GitHub', link: 'https://github.com/open-agenthub/open-agenthub' }
    ],
    sidebar: [
      {
        text: 'Getting started',
        items: [
          { text: 'Install', link: '/getting-started' },
          { text: 'Upgrading', link: '/upgrading' }
        ]
      },
      {
        text: 'Running sessions',
        items: [
          { text: 'Auto approve', link: '/auto-approve' }
        ]
      },
      {
        text: 'Integrations',
        items: [
          { text: 'Chat (Telegram & Signal)', link: '/chat' },
          { text: 'Git (GitHub & GitLab)', link: '/git' }
        ]
      },
      {
        text: 'Reference',
        items: [
          { text: 'Troubleshooting', link: '/troubleshooting' }
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/open-agenthub/open-agenthub' }
    ],
    editLink: {
      pattern: 'https://github.com/open-agenthub/open-agenthub.github.io/edit/main/docs-src/:path',
      text: 'Edit this page on GitHub'
    },
    search: { provider: 'local' },
    footer: {
      message: 'AGPL-3.0 core with an enterprise edition under ee/.',
      copyright: '© Maik Boltze'
    }
  }
})
