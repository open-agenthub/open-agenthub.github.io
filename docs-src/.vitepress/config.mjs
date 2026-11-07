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
          { text: 'Feature overview', link: '/features' },
          { text: 'Install', link: '/getting-started' }
        ]
      },
      {
        text: 'Working with sessions',
        items: [
          { text: 'Sessions', link: '/sessions' },
          { text: 'Projects', link: '/projects' },
          { text: 'Workspace', link: '/workspace' },
          { text: 'Questions and approvals', link: '/questions-approvals' },
          { text: 'Auto approve', link: '/auto-approve' },
          { text: 'Provider login', link: '/provider-login' },
          { text: 'Choosing a model', link: '/models' },
          { text: 'Continue locally', link: '/local-sessions' }
        ]
      },
      {
        text: 'Files and tools',
        items: [
          { text: 'Session files', link: '/files' },
          { text: 'Integrated browser', link: '/browser' },
          { text: 'Previewing a page', link: '/preview' },
          { text: 'Network ports', link: '/network-ports' },
          { text: 'Secrets', link: '/secrets' },
          { text: 'Skill library', link: '/skills' },
          { text: 'MCP servers for sessions', link: '/mcp-servers' },
          { text: 'Built-in tools', link: '/session-tools' }
        ]
      },
      {
        text: 'Collaboration',
        items: [
          { text: 'Sharing (Enterprise)', link: '/sharing' }
        ]
      },
      {
        text: 'Integrations',
        items: [
          { text: 'Chat (Telegram & Signal)', link: '/chat' },
          { text: 'Slack (Enterprise)', link: '/slack' },
          { text: 'Git (GitHub & GitLab)', link: '/git' },
          { text: 'MCP clients', link: '/mcp' }
        ]
      },
      {
        text: 'Account and administration',
        items: [
          { text: 'Settings', link: '/settings' },
          { text: 'Usage and cost', link: '/usage' },
          { text: 'Administration', link: '/admin' }
        ]
      },
      {
        text: 'Operators',
        items: [
          { text: 'Chart values', link: '/chart-values' },
          { text: 'Upgrading', link: '/upgrading' }
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
