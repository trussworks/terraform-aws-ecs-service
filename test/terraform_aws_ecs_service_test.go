package test

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

// Retrieve tasks associated with a cluster
func GetTasks(t *testing.T, region string, clusterName string) *ecs.ListTasksOutput {
	taskList, err := GetTasksE(t, region, clusterName)
	require.NoError(t, err)
	return taskList
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

	// Need to spin and wait to allow time for resources to get up
	maxRetries := 3
	retryDuration, _ := time.ParseDuration("30s")
	_, err = retry.DoWithRetryE(t, "Get tasks", maxRetries, retryDuration,
		func() (string, error) {
			tasks, _ := ecsClient.ListTasks(params)

			if len(tasks.TaskArns) == 0 {
				return "Did not retrieve tasks", fmt.Errorf("We returned empty tasks %v", tasks.TaskArns)
			}
			returnTaskList = tasks
			return "Retrieved tasks", nil
		},
	)
	if err != nil {
		return returnTaskList, err
	}

	return returnTaskList, nil
}

// Retrieve ENI from task ARNs and cluster
func GetEni(t *testing.T, region string, cluster string, taskArns []*string) *string {
	eni, err := GetEniE(t, region, cluster, taskArns)
	require.NoError(t, err)
	return eni
}

func GetEniE(t *testing.T, region string, cluster string, taskArns []*string) (*string, error) {
	var eniDetail *string
	ecsClient, err := aws.NewEcsClientE(t, region)
	if err != nil {
		return nil, err
	}

	params := &ecs.DescribeTasksInput{
		Cluster: awssdk.String(cluster),
		Tasks:   taskArns,
	}

	maxRetries := 3
	retryDuration, _ := time.ParseDuration("30s")
	_, err = retry.DoWithRetryE(t, "Get tasks", maxRetries, retryDuration,
		func() (string, error) {
			returnedTasks, _ := ecsClient.DescribeTasks(params)
			errMessage := "failed to look up public elastic network interface"
			if len(returnedTasks.Tasks) == 0 {
				return errMessage, fmt.Errorf("returned empty tasks %v", returnedTasks.Tasks)
			} else if len(returnedTasks.Tasks[0].Attachments) == 0 {
				return errMessage, fmt.Errorf("returned empty task attachements %v", returnedTasks.Tasks[0].Attachments)
			} else if len(returnedTasks.Tasks[0].Attachments[0].Details) == 1 {
				return errMessage, fmt.Errorf("returned task without public elastic network interface %v", returnedTasks.Tasks[0].Attachments)
			} else {
				eniDetail = returnedTasks.Tasks[0].Attachments[0].Details[1].Value
				return "restrieved public elastice network interface", nil
			}
		},
	)
	if err != nil {
		return eniDetail, err
	}
	return eniDetail, nil
}

// Retrieve Public IP from ENI
func GetPublicIP(t *testing.T, region string, enis []string) *string {
	publicIP, err := GetPublicIPE(t, region, enis)
	require.NoError(t, err)
	return publicIP
}

func GetPublicIPE(t *testing.T, region string, enis []string) (*string, error) {
	ec2Client := aws.NewEc2Client(t, region)

	params := &ec2.DescribeNetworkInterfacesInput{
		NetworkInterfaceIds: awssdk.StringSlice(enis),
	}
	eniDetail, err := ec2Client.DescribeNetworkInterfaces(params)
	if err != nil {
		return nil, err
	}

	publicIP := eniDetail.NetworkInterfaces[0].Association.PublicIp
	return publicIP, nil
}

func TestTerraformAwsEcsServiceSimple(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/simple")

	ecsServiceName := fmt.Sprintf("terratest-simple-%s", strings.ToLower(random.UniqueId()))
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
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Step through cluster and task to retrieve public IP of instance
	tasksOutput := GetTasks(t, awsRegion, ecsServiceName)
	singleTaskEni := GetEni(t, awsRegion, ecsServiceName, tasksOutput.TaskArns)
	publicIP := GetPublicIP(t, awsRegion, []string{*singleTaskEni})

	testURL := fmt.Sprintf("http://%v", *publicIP)
	expectedText := "Hello, world!"
	tlsConfig := tls.Config{}
	maxRetries := 2
	timeBetweenRetries := 30 * time.Second

	http_helper.HttpGetWithRetry(t, testURL, &tlsConfig, 200, expectedText, maxRetries, timeBetweenRetries)

}
