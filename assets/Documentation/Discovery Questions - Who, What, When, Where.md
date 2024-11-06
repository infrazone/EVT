| **Section**                             | **Subsection**               | **Question**                                                           | Answers |
| --------------------------------------- | ---------------------------- | ---------------------------------------------------------------------- | ------- |
| **1. Access and Security Requirements** | **Account Provisioning**     | What is the process for getting Azure AD and GCP accounts provisioned? |         |
|                                         |                              | Who is the point of contact for access requests?                       |         |
|                                         |                              | What is the expected turnaround time for access provisioning?          |         |
|                                         |                              | Are there any specific security clearances needed?                     |         |
|                                         | **Network Access**           | Will we need VPN access or can we work via whitelisted IPs?            |         |
|                                         |                              | What are the conditional access policies we need to comply with?       |         |
|                                         |                              | Are there specific locations or networks we must work from?            |         |
|                                         |                              | What is the process for IP whitelisting?                               |         |
|                                         | **PIM/Privileged Access**    | If you use PIM in Azure, what is your process for approving?           |         |
|                                         |                              | What is the process for PIM role activation in Azure?                  |         |
|                                         |                              | What is the maximum duration for PIM role assignments in Azure?        |         |
|                                         |                              | Who approves PIM role activations in Azure?                            |         |
|                                         |                              | What justification is needed for role activation in Azure?             |         |
|                                         | **GCP Privileged Access**    | What is your process for approving privileged access in GCP?           |         |
|                                         |                              | How is privileged access managed in GCP?                               |         |
|                                         |                              | What is the process for role activation in GCP?                        |         |
|                                         |                              | Who approves access requests in GCP?                                   |         |
|                                         |                              | Are there any specific security clearances needed for GCP access?      |         |
| **2. Environment Assessment**           | **Azure Environment**        | How many management groups are in scope?                               |         |
|                                         |                              | What is the current management group hierarchy?                        |         |
|                                         |                              | How many subscriptions need to be covered?                             |         |
|                                         |                              | Are there any subscriptions that should be excluded?                   |         |
|                                         | **GCP Environment**          | How many organizations are in scope?                                   |         |
|                                         |                              | What is the project hierarchy?                                         |         |
|                                         |                              | Are there any projects that should be excluded?                        |         |
|                                         |                              | What is the current labeling strategy?                                 |         |
| **3. Current State Analysis**           | **Resource Organization**    | How are resources currently organized?                                 |         |
|                                         |                              | What naming conventions are in place?                                  |         |
|                                         |                              | What is the resource hierarchy?                                        |         |
|                                         |                              | Are there environment segregations (Dev/Test/Prod)?                    |         |
| **4. Requirements Gathering**           | **Tag Strategy**             | What are the mandatory tags required?                                  |         |
|                                         |                              | What are the allowed values for each tag?                              |         |
|                                         |                              | Should tags be inherited from parent resources?                        |         |
|                                         |                              | How should tag conflicts be handled?                                   |         |
|                                         | **Policy Requirements**      | What tag enforcement policies are needed?                              |         |
|                                         |                              | Should we prevent deployment of untagged resources?                    |         |
|                                         |                              | How should non-compliant resources be handled?                         |         |
|                                         |                              | What reporting is needed for tag compliance?                           |         |
| **5. Implementation Details**           | **Timeline and Phasing**     | Are there specific milestones within the 7 weeks?                      |         |
|                                         |                              | What is the preferred order for implementation?                        |         |
|                                         |                              | Do you need a pilot phase before full rollout?                         |         |
|                                         |                              | Are there any blackout periods to be aware of?                         |         |
|                                         | **Change Management**        | What is the change management process?                                 |         |
|                                         |                              | Who needs to approve changes?                                          |         |
|                                         |                              | What are the change windows?                                           |         |
|                                         |                              | What is the rollback process?                                          |         |
| **6. Operational Requirements**         | **Support Model**            | Who will maintain the tagging solution after implementation?           |         |
|                                         |                              | What documentation is required?                                        |         |
|                                         |                              | What training needs to be provided?                                    |         |
|                                         |                              | What is the support escalation path?                                   |         |
|                                         | **Monitoring and Reporting** | What tag compliance reporting is needed?                               |         |
|                                         |                              | Who needs access to reports?                                           |         |
|                                         |                              | What metrics need to be tracked?                                       |         |
|                                         |                              | How often should reports be generated?                                 |         |
| **7. Success Criteria**                 | **Project Success**          | What defines successful implementation?                                |         |
|                                         |                              | What are the key deliverables expected?                                |         |
|                                         |                              | What are the acceptance criteria?                                      |         |
|                                         |                              | How will success be measured?                                          |         |
|                                         | **Validation Requirements**  | What testing is required?                                              |         |
|                                         |                              | Who needs to sign off on the implementation?                           |         |
|                                         |                              | What validation documentation is needed?                               |         |
|                                         |                              | What are the performance requirements?                                 |         |
| **8. Risk Assessment**                  | **Known Risks**              | Are there any known technical limitations?                             |         |
|                                         |                              | What are the critical business impacts?                                |         |
|                                         |                              | Are there any compliance concerns?                                     |         |
|                                         |                              | What are the main risks we should be aware of?                         |         |
| **9. Tools and Technology**             | **Development Tools**        | What tools are approved for use?                                       |         |
|                                         |                              | Are there any specific version requirements?                           |         |
|                                         |                              | What is the process for tool installation/access?                      |         |
|                                         |                              | Are there any prohibited tools?                                        |         |
|                                         | **Integration Requirements** | What systems need to integrate with the tagging solution?              |         |
|                                         |                              | Are there any API limitations?                                         |         |
|                                         |                              | What authentication methods are required?                              |         |
|                                         |                              | Are there any rate limiting concerns?                                  |         |
| **10. Documentation Requirements**      | **Required Documentation**   | What documentation standards must be followed?                         |         |
|                                         |                              | Who are the documentation stakeholders?                                |         |
|                                         |                              | Where should documentation be stored?                                  |         |
|                                         |                              | What formats are required?                                             |         |
|                                         | **Knowledge Transfer**       | Who needs to be trained?                                               |         |
|                                         |                              | What type of training is required?                                     |         |
|                                         |                              | When should training be delivered?                                     |         |
|                                         |                              | What training materials are needed?                                    |         |