*** Settings ***
Library     RPA.Excel.Files
Library     RPA.Robocorp.WorkItems
Library     RPA.Crypto
Library     RPA.RobotLogListener
Suite Setup   Get the encryption key

*** Tasks ***
Produce Items
    [Documentation]
    ...    Read rows from Excel.
    ...    Encrypt the sensitive data
    ...    Create output work items.

    Register Protected Keywords    Process file
    ${paths}=    Get Work Item Files    *.xlsx

    FOR    ${path}    IN    @{paths}
        Process file    ${path}
    END

    Release Input Work Item    DONE

*** Keywords ***
Get the encryption key
    Use Encryption Key From Vault    WIEncryption


Process file
    [Arguments]    ${path}
    Open Workbook    ${path}
    ${table}=    Read Worksheet As Table    header=True
    FOR    ${row}    IN    @{table}
        ${plain_text_ID}=   Set Variable   ${row}[ID]
        ${encrypted_FN}=    Encrypt String    ${row}[First Name]
        ${encrypted_LN}=    Encrypt String    ${row}[Last Name]
        ${encrypted_SSN}=   Encrypt String    ${row}[SSN]
        ${encrypted_FN}=    Convert To String    ${encrypted_FN}
        ${encrypted_LN}=    Convert To String    ${encrypted_LN}
        ${encrypted_SSN}=   Convert To String    ${encrypted_SSN}

        ${variables}=    Create Dictionary
        ...    ID=${plain_text_ID}
        ...    First Name=${encrypted_FN}
        ...    Last Name=${encrypted_LN}
        ...    SSN=${encrypted_SSN}

        Create Output Work Item
        ...    variables=${variables}
        ...    save=True
    END