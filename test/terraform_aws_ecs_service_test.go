package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

// func TestTerraformAwsEcsServiceSimple(t *testing.T) {
// 	t.Parallel()

// tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/simple")
// 	ecsServiceName := fmt.Sprintf("terratest-simple-%s", strings.ToLower(random.UniqueId()))
// 	awsRegion := "us-west-2"

// 	terraformOptions := &terraform.Options{
// 		// The path to where our Terraform code is located
// 		TerraformDir: tempTestFolder,
// 		// Variables to pass to our Terraform code using -var options
// 		Vars: map[string]interface{}{
// 			"ecs_service_name": ecsServiceName,
// 		},
// 		EnvVars: map[string]string{
// 			"AWS_DEFAULT_REGION": awsRegion,
// 		},
// 	}

// 	defer terraform.Destroy(t, terraformOptions)
// 	terraform.InitAndApply(t, terraformOptions)

// }

func GetTasks(t *testing.T, region string, clusterName string) *ecs.ListTasksOutput {
	taskName, err := GetTasksE(t, region, clusterName)
	require.NoError(t, err)
	return taskName
}

func GetTasksE(t *testing.T, region string, clusterName string) (*ecs.ListTasksOutput, error) {
	var returnTaskList *ecs.ListTasksOutput
	ecsClient, err := aws.NewEcsClientE(t, region)
	if err != nil {
		return returnTaskList, err
	}

	params := &ecs.ListTasksInput{
		Cluster: awssdk.String(clusterName),
	}
	maxRetries := 3
	retryDuration, _ := time.ParseDuration("30s")
	_, err = retry.DoWithRetryE(t, "Get tasks", maxRetries, retryDuration,
		func() (string, error) {
			tasks, err := ecsClient.ListTasks(params)
			if err != nil {
				return "Did not retrieve tasks", err
			}
			returnTaskList = tasks
			return "Retrieved tasks", nil
		},
	)

	if err != nil {
		return returnTaskList, err
	}

	returnedTasks := fmt.Sprintf("HERE IT IS ecsClusterTask, %v", returnTaskList)

	if returnedTasks == "" {
		return returnTaskList, nil
	}

	return returnTaskList, fmt.Errorf(returnedTasks)
	// return returnTaskList, nil
}

func TestTerraformAwsEcsServiceContainer(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/container-image")

	ecsServiceName := fmt.Sprintf("terratest-container-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-west-2"
	vpcAzs := aws.GetAvailabilityZones(t, awsRegion)[:3]

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"test_name": ecsServiceName,
			"vpc_azs":   vpcAzs,
			"region":    awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	GetTasks(t, awsRegion, ecsServiceName)
	// testURL := "https://10.0.0.20"
	// expectedText := "Hello, world!"
	// tlsConfig := tls.Config{}
	// maxRetries := 2
	// timeBetweenRetries := 30 * time.Second

	// http_helper.HttpGetWithRetry(t, testURL, &tlsConfig, 200, expectedText, maxRetries, timeBetweenRetries)

}
