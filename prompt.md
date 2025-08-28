Act as a DevOps architect. Your task is to design a modern application delivery framework that emulates the key features of the open-source Lagoon platform. This new framework must be built using the following core technologies:

**- Infrastructure as Code:** Terraform
**- Terraform Environment Management:** A folder-based structure with a tool like Terragrunt or similar to ensure a DRY (Don't Repeat Yourself) configuration across environments.
**- Cloud Provider:** AWS
**- Container Orchestration:** AWS ECS (Elastic Container Service)
**- Source Code Repository & CI/CD:** GitHub
**- Serverless-First Principle:** All AWS services used should be serverless wherever possible to minimize operational overhead.

Your framework should be a comprehensive, self-hosted solution that provides a "ZeroOps" experience for developers. It must enable automated, consistent, and scalable deployments.

Detail the framework's architecture and workflow. The solution must include:

**1. Automated CI/CD Workflows:**
   - A pipeline that automatically triggers on a `git push` to a GitHub repository.
   - The process for building and containerizing applications using Docker.
   - The method for pushing the built container images to a private registry (e.g., AWS ECR).
   - How different environments (e.g., staging, production) are managed from a single GitHub repository using branching strategies and environment variables.
   - The process for creating a new, isolated, ephemeral environment when a pull request is opened, and for automatically destroying that environment when the pull request is closed or merged.
   - The plan for how ephemeral and development environments will share a single, long-lived Amazon RDS database, including:
     * Strategy for using Aurora Serverless v2 for cost-effective scaling.
     * Schema management approach (separate databases vs. schema isolation).
     * Data seeding strategy for new environments (anonymized production data vs. fixtures).
     * Performance isolation to prevent development workloads from affecting staging/production.
   - The inclusion of automated processes for copying the database and files between environments (e.g., from staging to production or from production to development) to facilitate data promotion and refresh.
   - The implementation of blue/green deployment strategies for both the application and the database to ensure zero-downtime releases.
   - **Rollback Procedures:** Automated rollback triggers and manual override processes for failed deployments.

**2. Developer-Centric Experience:**
   - A system that ensures consistency between local development and production environments.
   - The ability for developers to run a local development environment that is identical to the production environment using Docker Compose.
   - A strategy for how developers will get their secrets (e.g., database credentials, API keys) for their local docker-compose setup from a secure source like AWS Secrets Manager, rather than hardcoding them.
   - The command-line and user interface components developers would use to interact with the system.

**3. Performance and Scalability:**
   - How the serverless ECS cluster and services are provisioned and managed on AWS (e.g., using Fargate for a serverless experience).
   - The strategy for implementing microservices and how they can be individually scaled using AWS's serverless auto-scaling features.
   - The use of AWS CloudFront for the staging and production environments to serve as a Content Delivery Network (CDN) to enhance performance and security, including how this managed service will be provisioned with Terraform, integrated with the Application Load Balancer, and configured with SSL certificates from AWS Certificate Manager.
   - The inclusion of a scalable, serverless caching layer for the application using Amazon ElastiCache for Valkey.

**4. Operations and Security Features:**
   - The process for managing user roles and permissions using AWS IAM.
   - The use of dedicated IAM Roles for Tasks to grant fine-grained, least-privilege permissions to each ECS task for accessing other AWS services like S3 or RDS.
   - A solution for automated backups of application data using serverless services.
   - The method for automatically provisioning and managing SSL certificates using the serverless AWS Certificate Manager service.
   - A strategy for monitoring and logging builds and deployments using the serverless AWS CloudWatch and CloudTrail services.
   - The inclusion of AWS WAF for the CloudFront distributions in staging and production to protect against common web exploits and bots.
   - The plan for DNS management using Amazon Route 53, detailing how Terraform will provision and manage DNS records for all environments, including dynamic subdomains for ephemeral environments.
   - The creation of CloudWatch alarms and a notification system (e.g., using SNS) to alert on critical events, such as application errors, high latency, or deployment failures.
   - The plan for remote state management for Terraform, detailing how a remote backend will be configured using an S3 bucket to store the state file, and what best practices are needed for state locking.
   - The plan for secure secrets injection into the application container on AWS ECS, detailing how secrets from Secrets Manager will be directly injected into the container via the task definition rather than being retrieved by the application code.
   - **Compliance Requirements:** A plan to meet standards such as SOC2 and PCI-DSS, including secure logging, access controls, and data encryption.
   - **Disaster Recovery:** RTO/RPO requirements and a multi-region strategy for high availability and business continuity.
   - **Testing Strategy:** The framework should incorporate integration testing within ephemeral environments before code can be merged.
   - **Migration Strategy:** A plan for transitioning existing applications to the new framework with minimal downtime.
   - **Developer Onboarding:** Self-service capabilities for new team members to provision their development environments.
   - **Troubleshooting & Debugging:** Built-in tools for log aggregation, distributed tracing, and performance profiling across environments.

**Success Criteria:**
- Support for 10+ concurrent development environments
- Sub-5 minute deployment times for typical applications
- 99.9% uptime for production environments
- Complete environment provisioning in under 10 minutes
- **Application Types:** The framework must be language/framework agnostic, supporting any application that can be packaged into a Docker container.
- **Performance Requirements:** The production environment must be designed to handle:
  - Minimum of 100 requests per second (RPS) baseline load
  - Burst capacity up to 500 RPS during peak traffic
  - P99 latency of less than 200ms for API responses
  - Database connection pooling to handle concurrent users efficiently
  - Auto-scaling triggers based on CPU, memory, and request queue metrics

**Constraints:**
- Maximum monthly AWS costs should not exceed $500 for a small team (5-10 developers)
- All components must be region-agnostic for disaster recovery
- Framework must support both monolithic and microservice architectures
- **Budget Monitoring:** Implement AWS Budgets with automated alerts at 50%, 80%, and 95% of monthly spend limits
- **Resource Governance:** Enforce resource tagging policies and automated cleanup of unused resources after 7 days
- Cost Optimization:
  - Leverage on-demand and serverless services to pay only for what's used.
  - Implement scheduled shutdowns for non-production environments during off-hours.
  - Prioritize cost-effective instance types and configurations for all services.
  - Use ephemeral environments to keep development infrastructure costs near zero when not in use.
  - **Reserved Capacity:** For predictable workloads in production, consider Savings Plans or Reserved Instances for 20-30% cost reduction.

Please provide a detailed, step-by-step description of the entire end-to-end process, from a developer pushing code to a live, production deployment. The response should be structured and easy to understand for a technical audience.

**Expected Deliverables:**
1. **High-Level Architecture Overview**: Visual representation and component relationships
2. **Terraform Module Structure**: Recommended folder hierarchy with Terragrunt organization
3. **GitHub Actions Workflow Templates**: Complete CI/CD pipeline configurations for different scenarios
4. **Developer Workflow Guide**: Step-by-step processes for common development tasks
5. **Environment Management Strategy**: Detailed branching strategy and environment promotion workflows
6. **Security Implementation Guide**: IAM policies, secrets management, and compliance configurations
7. **Monitoring & Alerting Setup**: CloudWatch dashboards, alarms, and notification configurations
8. **Cost Management Framework**: Tagging strategies, budget alerts, and optimization recommendations

**Response Structure:**
- Begin with architectural overview and design principles
- Detail each major component with implementation specifics
- Include relevant configuration examples and code snippets
- Address potential challenges and mitigation strategies
- Provide implementation timeline and rollout phases
