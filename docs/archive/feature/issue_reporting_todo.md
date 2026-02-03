# Issue Reporting Feature - TODOs

## Future Enhancements (Post-V1)

These features should be considered for future iterations but are not part of the initial implementation:

### Performance & Scalability
- [ ] Implement rate limiting for AI queries per admin user
- [ ] Add caching layer for frequently asked AI questions
- [ ] Implement RAG (Retrieval-Augmented Generation) with vector embeddings when issue volume increases significantly
- [ ] Consider pagination or filtering for AI context (currently sends last 50 issues)

### Feature Improvements
- [ ] Add issue status management UI (transition between new/reviewed/archived)
- [ ] Implement bulk actions for issues (mark multiple as reviewed)
- [ ] Add export functionality (CSV/JSON export of issues)
- [ ] Create admin dashboard with issue statistics and trends over time  
- [ ] Add email notifications for admins when new issues are submitted
- [ ] Allow admins to respond to issues directly
- [ ] Implement issue categories or tags for better organization

### Security & Privacy
- [ ] Enhance PII scrubbing with more sophisticated detection
- [ ] Add audit logging for admin AI queries
- [ ] Implement data retention policies for old issues
- [ ] Consider GDPR compliance for user-submitted content

### AI Enhancements
- [ ] Support for multiple AI providers (Claude, Gemini) as fallbacks
- [ ] Implement streaming responses for better UX
- [ ] Add suggested prompts/questions for admins
- [ ] Create predefined report templates (daily summary, weekly trends, etc.)
- [ ] Allow customization of AI system prompt per organization

### Testing & Monitoring
- [ ] Add integration tests with real OpenAI API (optional, gated behind env var)
- [ ] Implement monitoring for AI API costs and usage
- [ ] Add alerts for unusual patterns in issue submissions
- [ ] Create dashboard for tracking AI query performance and accuracy

### User Experience
- [ ] Add rich text editor for issue submission
- [ ] Allow file attachments with issues
- [ ] Implement issue templates for common types of feedback
- [ ] Add user notification when their issue is reviewed/resolved
- [ ] Create public-facing status page showing addressed issues
