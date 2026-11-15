---
name: rewrite
description: "Rewrite any draft text, rough notes, bullet points, or Banglish/Bengali messages into 5 distinct workplace tones (Professional, Friendly, Short/Direct, Assertive, and Casual/Slack). Use when asked to rewrite, rephrase, polish, tone-adjust, or translate Banglish."
---

# Tone Rewriter Skill (English & Banglish)

Transform any rough draft, quick thoughts, raw lines, or **Banglish / Bengali** messages into multiple polished variations tailored for different audiences, contexts, and communication channels.

---

## When to Activate

Trigger this skill whenever:
- The user provides a few lines, rough notes, or draft message and wants different ways to say it.
- The user provides **Banglish** (Bengali written with Latin/English letters) or **Bengali** text (e.g., *"vaiya amar ajker kaj ses..."*, *"amar task ta akta vul entry hoye gase..."*).
- The user asks: *"how can I say this professionally?"*, *"make this friendly"*, *"give me different versions of this"*, or *"rewrite this message"*.
- The user invokes the `/rewrite` command.

---

## Output Structure

Whenever the user provides input text, provide **5 distinct, copy-paste-ready variations**:

### 1. 👔 Professional & Polite
> **Best for:** Client communication, managers, team leads (*"Vaiya" / "Sir"*), formal emails, Jira tickets, or PR reviews.
- Tone: Respectful, articulate, balanced, proactive, and business-ready.
- Eliminates awkward phrasing or literal translations while keeping the tone elevated and courteous.

### 2. 😊 Friendly & Warm
> **Best for:** Peers, cross-functional teammates, onboarding, 1-on-1s, or collaborative Slack/Teams channels.
- Tone: Approachable, positive, empathetic, and encouraging.
- Softens directives into supportive collaboration without losing clarity.

### 3. ⚡ Short & Direct (Executive / Concise)
> **Best for:** Busy executives, sprint standups, quick mobile updates, or urgent status pings.
- Tone: Zero fluff, high-signal, punchy, and instantly skimmable (1–2 sentences or clean bullet points).
- Gets straight to the point and call-to-action.

### 4. 🎯 Assertive & Confident
> **Best for:** Setting expectations, deadlines, blockers, scope boundaries, or follow-ups.
- Tone: Decisive, firm, confident, and polite.
- Eliminates weak language (e.g., replaces *"sorry to bother you, but maybe..."* with *"Following up on this so we can keep the schedule on track"*).

### 5. 💬 Casual & Conversational
> **Best for:** Daily internal team chat, dev group channels, Discord, or quick Slack DMs.
- Tone: Natural, modern, relaxed, and conversational while staying clear and professional.

---

## Core Transformation Principles

1. **Preserve All Technical Context & Entities**:
   - Never alter or mistranslate story numbers, ticket IDs, API names, endpoints, branch names, file names, or PR titles (e.g., `Story 5 – Level-Shift Override`, `TimeOffExceptions.tsx`, `GET /practitioners`, `#339`).
   - Retain colleague and lead names intact (e.g., *Suporno Vai*, *Shofiq vai*).

2. **Understand Bangladeshi Tech Workplace Nuance (Banglish)**:
   - **Addressing seniors/leads**: Forms like *"Vaiya"* / *"Apu"* / *"Boss"* / *"Sir"*:
     - In team chat (Slack/Teams/WhatsApp), Bangladeshi engineers frequently use *"Vaiya"* or *"Hi [Name] Vai"*. Respect this tone.
     - For international teams or formal emails, translate naturally to *"Hi [Name]"* or a professional greeting.
   - **Respectful requests**: Phrasing like *"upkar hoi"* / *"dile valo hoto"* / *"ektu dekhe dile"* $\rightarrow$ *"Could you please..."*, *"I would really appreciate it if..."*.
   - **Proactive framing**: Frame availability, blockers, and self-directed work (e.g., performance optimization, slow API fixes) as positive contributions.

3. **Eliminate Awkward Literal Translations**:
   - ❌ *"In my hand only today work is there"* $\rightarrow$ *"I currently only have today's task on my plate."*
   - ❌ *"Mistake one task fallen"* $\rightarrow$ *"I accidentally logged a time entry for the wrong task."*
   - ❌ *"Many places API slow those I will fix"* $\rightarrow$ *"I will focus on optimizing the slow API endpoints across the app."*

4. **Remove Unnecessary Weak Words & Over-Apologizing**:
   - Unless an actual mistake was made, remove unnecessary apologies like *"sorry for asking"* or *"just wanted to check"*.
   - Replace with constructive, clear, and proactive framing.

5. **Detected Recommendation**:
   - At the bottom of each response, include a short **💡 Recommendation** note suggesting which variation best matches the user's audience and situation.

---

## Examples

### Example 1: English Rough Draft (Outage / Blocker)
> *Input:* "I can't finish this task today because the API is not working. Will do it tomorrow."

- **👔 Professional:** *"I am currently blocked on this task due to an API outage on the backend. I have documented the issue and will resume and complete the work first thing tomorrow once the endpoint is restored."*
- **😊 Friendly:** *"Hey team, heads up that I hit a blocker with the API today, so I won't be able to wrap this task up by EOD. Planning to jump right back on it tomorrow morning!"*
- **⚡ Short & Direct:** *"Blocked by backend API outage today. Resuming tomorrow morning for completion."*
- **🎯 Assertive:** *"This task cannot proceed today due to the API being down. I'll need the endpoint operational tomorrow morning so we can deliver this without further delay."*
- **💬 Casual:** *"Heads up, backend API is acting up so I'm paused on this for today. Gonna wrap it up tomorrow morning instead."*

---

### Example 2: Banglish Task Completion & Next Steps
> *Input:* "vaiya amar ajker kaj ses. kal theke notun feature dhormo."

- **👔 Professional:** *"Hi Vaiya, I have completed all my assigned tasks for today. I will be ready to begin work on the new feature starting tomorrow morning."*
- **😊 Friendly:** *"Hey Vaiya, all wrapped up with today's tasks! Ready to kick off the new feature first thing tomorrow."*
- **⚡ Short & Direct:** *"Today's tasks completed. Starting the new feature tomorrow."*
- **🎯 Assertive:** *"I've finished all deliverables scheduled for today and will proceed with the new feature implementation tomorrow."*
- **💬 Casual:** *"Done with today's tasks, Vaiya! Will pick up the new feature tomorrow."*

---

### Example 3: Banglish Mistaken Time Log
> *Input:* "Asslamualikum vaiya amar task bul akta pore gase aita ajker time ta remove kore dile upkar hoi."

- **👔 Professional:** *"Assalamu Alaikum, Vaiya. I accidentally logged time under the wrong task today. Could you please help me remove or reset today's entry? I'd really appreciate your help."*
- **😊 Friendly:** *"Hi Vaiya, I accidentally added hours to the wrong task today. Could you please delete today's entry when you get a chance? Thanks a lot!"*
- **⚡ Short & Direct:** *"Accidental time log on wrong task today. Please remove today's entry when convenient."*
- **🎯 Assertive:** *"I need to correct today's time log as it was submitted under the wrong task. Please reset today's entry so I can log it accurately."*
- **💬 Casual:** *"Hey Vaiya, logged time on the wrong task by mistake today. Could you clear today's entry when you have a sec? Thanks!"*

---

### Example 4: Banglish PR Review Request
> *Input:* "Vaiya PR create korechi, ektu review kore dile merge kore ditam"

- **👔 Professional:** *"Hi Vaiya, I've opened the pull request for [Feature/Bug]. Could you please review it when you have a moment so we can proceed with the merge? Thank you!"*
- **😊 Friendly:** *"Hey Vaiya! PR is ready whenever you have a chance to take a look. Once you review, I'll go ahead and merge it. Thanks!"*
- **⚡ Short & Direct:** *"PR created and ready for review. Pending your approval to merge."*
- **🎯 Assertive:** *"PR has been submitted for review. Please approve once reviewed so we can merge without blocking the sprint."*
- **💬 Casual:** *"PR is up, Vaiya! Give it a quick look when you're free so I can get it merged."*
