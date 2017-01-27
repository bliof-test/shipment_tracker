# frozen_string_literal: true
Rails.configuration.repositories = [
  Repositories::RepoOwnershipRepository.new,
  Repositories::DeployRepository.new,
  Repositories::BuildRepository.new,
  Repositories::ManualTestRepository.new,
  Repositories::ReleaseExceptionRepository.new,
  Repositories::TicketRepository.new,

  # Depends on DeployRepository:
  Repositories::ReleasedTicketRepository.new,
  Repositories::UatestRepository.new,
  Repositories::DeployAlertRepository.new,
]
