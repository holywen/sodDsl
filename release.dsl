
release 'sod-dev-release', {
  plannedEndDate = '2022-01-25'
  plannedStartDate = '2022-01-11'
  projectName = 'SoD-Holy'

  pipeline 'pipeline_sod-dev-release', {
    projectName = 'SoD-Holy'
    releaseName = 'sod-dev-release'

    formalParameter 'ec_stagesToRun', {
      expansionDeferred = '1'
    }

    stage 'Dev', {
      colorCode = '#289ce1'
      pipelineName = 'pipeline_sod-dev-release'
      projectName = 'SoD-Holy'

      gate 'PRE', {
        projectName = 'SoD-Holy'

        task 'resource-check', {
          gateType = 'PRE'
          projectName = 'SoD-Holy'
          subprocedure = 'resourceCheck'
          subproject = 'SoD-Holy'
          taskType = 'PROCEDURE'
        }

        task 'approval', {
          gateType = 'PRE'
          notificationEnabled = '1'
          notificationTemplate = 'ec_default_gate_task_notification_template'
          projectName = 'SoD-Holy'
          subproject = 'SoD-Holy'
          taskType = 'APPROVAL'
          approver = [
            'Everyone',
          ]
        }
      }

      gate 'POST', {
        projectName = 'SoD-Holy'
      }

      task 'Deploy', {
        deployerRunType = 'serial'
        projectName = 'SoD-Holy'
        subproject = 'SoD-Holy'
        taskType = 'DEPLOYER'
      }
    }

    stage 'QA', {
      colorCode = '#289ce1'
      pipelineName = 'pipeline_sod-dev-release'
      projectName = 'SoD-Holy'

      gate 'PRE', {
        projectName = 'SoD-Holy'

        task 'resource-check', {
          gateType = 'PRE'
          projectName = 'SoD-Holy'
          subprocedure = 'resourceCheck'
          subproject = 'SoD-Holy'
          taskType = 'PROCEDURE'
        }

        task 'approval', {
          gateType = 'PRE'
          notificationEnabled = '1'
          notificationTemplate = 'ec_default_gate_task_notification_template'
          projectName = 'SoD-Holy'
          subproject = 'SoD-Holy'
          taskType = 'APPROVAL'
          approver = [
            'Everyone',
          ]
        }
      }

      gate 'POST', {
        projectName = 'SoD-Holy'
      }

      task 'Deploy', {
        deployerRunType = 'serial'
        projectName = 'SoD-Holy'
        subproject = 'SoD-Holy'
        taskType = 'DEPLOYER'
      }
    }

    stage 'Prod', {
      colorCode = '#289ce1'
      pipelineName = 'pipeline_sod-dev-release'
      projectName = 'SoD-Holy'

      gate 'PRE', {
        projectName = 'SoD-Holy'

        task 'launcher-check', {
          gateType = 'PRE'
          projectName = 'SoD-Holy'
          subprocedure = 'launcherCheck'
          subproject = 'SoD-Holy'
          taskType = 'PROCEDURE'
        }

        task 'resource-check', {
          gateType = 'PRE'
          projectName = 'SoD-Holy'
          subprocedure = 'resourceCheck'
          subproject = 'SoD-Holy'
          taskType = 'PROCEDURE'
        }

        task 'deployment to production', {
          gateType = 'PRE'
          notificationEnabled = '1'
          notificationTemplate = 'ec_default_gate_task_notification_template'
          projectName = 'SoD-Holy'
          subproject = 'SoD-Holy'
          taskType = 'APPROVAL'
          approver = [
            'Everyone',
          ]
        }

        task 'approverCheck', {
          gateCondition = '''$[/javascript 
 if( myGateRuntime.tasks[\'deployment to production\'].lastModifiedBy != myPipelineRuntime.launchedByUser) {
   true;
}
else {
  setProperty("/myTaskRuntime/evidence", "Approver and Initiator can not be the same")
  false;
}
]'''
          gateType = 'PRE'
          projectName = 'SoD-Holy'
          subproject = 'SoD-Holy'
          taskType = 'CONDITIONAL'
        }
      }

      gate 'POST', {
        projectName = 'SoD-Holy'
      }

      task 'Deploy', {
        deployerRunType = 'serial'
        projectName = 'SoD-Holy'
        subproject = 'SoD-Holy'
        taskType = 'DEPLOYER'
      }
    }
  }

  deployerApplication 'SoDApp', {
    orderIndex = '1'
    processName = 'Deploy'
    smartDeploy = '0'

    deployerConfiguration '3830323d-7360-11ec-95cd-02426ce5a855', {
      deployerTaskName = 'Deploy'
      environmentName = 'SoDApp-Dev'
      projectName = 'SoD-Holy'
      stageName = 'Dev'
    }

    deployerConfiguration 'a50670db-7360-11ec-9ad4-02426ce5a855', {
      deployerTaskName = 'Deploy'
      environmentName = 'SoDApp-QA'
      projectName = 'SoD-Holy'
      stageName = 'QA'
    }

    deployerConfiguration 'a5145330-7360-11ec-b968-02426ce5a855', {
      deployerTaskName = 'Deploy'
      environmentName = 'SoDApp-Prod'
      projectName = 'SoD-Holy'
      stageName = 'Prod'
    }
  }
}
