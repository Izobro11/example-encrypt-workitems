# Encrypt work items and prevent logging for sensitive data
 
Working with sensitive data? This robot example is for you! It shows how to leverage Robocorp's powerful [Work Data Management](https://robocorp.com/docs/control-room/unattended/work-data-management) with it's Work Items for managing work queues and parallel execution, but in a way that the sensitive data is not visible in outside of your own environment.

This robot shows two key concepts:

- How to encrypt a Work Item before it's lands Control Room, and how to decrypt it in the next process step.
- How to prevent task logging for the sensitive data. Remember that by default the task logs are also sent to Control Room.

##  Step 1: Create your encryption key

As a first step, an encryption key needs to be created. This example stores it in the Robocorp Vault, where it is secure, but easily available for the robots. Create a Vault called `WIEncryption` in your Workspace first, with an empty key named `key`. Notice, that this needs to be created before generating the key manually.

Next run the task `Generate Key` from this repo, from file [keygen.robot](https://github.com/robocorp/example-encrypt-workitems/blob/master/keygen.robot). It will create a fresh encryption key in you Vault. As a result, your Vault will look like this:

![image](https://github.com/robocorp/example-encrypt-workitems/assets/40179958/3a44c756-d9e8-4ed4-a276-25438b7a8ad9)

## Step 2: Encyrpt when creating the work items

The robot uses simplified [producer/consumer template](https://robocorp.com/portal/robot/robocorp/template-producer-consumer), where the producer reads items from the customers.xlsx file, and sends them as work items for the next consumer step. The data in the excel contains (simulated) personal data, and we want to encrypt everything else than the ID. Thus first and last name as well as social security number are not exposed to Control Room even if someone goes and looks for work item data. This is a handy way, as it will leave the ID field readable also in the control room, which will make error detection and bot operations a whole lot easier.

First make sure to import the crypto library (in both producer and consumer):

```robot
Library     RPA.Crypto
```

Next we have created a keyword that is run in Suite Setup. It sets up the crypto library to know where to look for the encryption and decryption key. This is needed also in both producer and consumer:

```robot
*** Keywords ***
Get the encryption key
    Use Encryption Key From Vault    WIEncryption
```

Then it's time for encryption. Each of the datapoints go through two steps like this:

```robot
    ${encrypted_FN}=    Encrypt String    ${row}[First Name]
    ${encrypted_FN}=    Convert To String    ${encrypted_FN}
```

As a result, when creating the output work item there will only be a string full of characters that do not make much sense (without the key).

![image](https://github.com/robocorp/example-encrypt-workitems/assets/40179958/9815a660-4fea-42e1-9cdd-f3513b613d50)

## Step 3: Decrypt when consuming the work items

In your consumer bot (after adding the library import and suite setup), it's then easy to go backwards and decrypt the data. Here we have created a separate keyword for decryption, which is only one keyword in itself. This may seem unnecessary, but there is a reason, which is related to suppressing the logging we will look at the next step. So our keyword for decryption looks like this:

```robot
Decrypt one thing
    [Documentation]    Separate keyword in order to be able
    ...                to register it as a protected keyword and
    ...                suppress logging of potentially sensitive data.
    [Arguments]    ${encrypted}
    ${decrypted}=    Decrypt String    ${encrypted}
    [Return]    ${decrypted}
```

And using it in the code is simple as this:

```robot
    ${decrypted_FN}=   Decrypt one thing    ${payload}[First Name]
```

## Step 4: Restrict Task Logging

Finally, time to make sure no traces of sensitive data is left to logs. The example shows two different methods.

Producer has a `FOR` loop, where each of the rows actually contains sensitive data. By default Robot Framework logs the contents of items that the loop iterates, so we need to address that. Along with the solution, we actually get rid of logging anything within that loop, so we don't need to worry about anything else, as long as all the sensitive data is only within the context of the loop.

This is solved with a little trick in [robot.yaml](https://github.com/robocorp/example-encrypt-workitems/blob/0893493e7cc28292c5544f54eb82c7b3aed6c586/robot.yaml#L7) configuration file. When declaring the task entry points, we use python call, and add `--flattenkeywords for` in our command. That's it, like this:

```yaml
tasks:
  Encrypt:
    # This shows how to suppress logging of item data for FOR loop.
    shell: python -m robot --flattenkeywords for --report NONE --outputdir output --logtitle "Task log" producer.robot
```

For the consumer, we'll address it with a different method. This involves registering a keyword as "protected". That's why we moved the decryption code under a separate keyword. Two steps required. First import this:

```robot
Library     RPA.RobotLogListener
```

Then somewhere in before the sensitive data, register the particulart keyword as protected with this call:

```robot
    Register Protected Keywords    Decrypt one thing
```

NOTE: The consumer logs the unprotected data to the task log on [row 40](https://github.com/robocorp/example-encrypt-workitems/blob/0893493e7cc28292c5544f54eb82c7b3aed6c586/consumer.robot#L40) onwards just to illustrate how important it is to make sure you have properly secured all the possible exposures. You would never log sensitive data like that, promise?
