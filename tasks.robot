*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the image

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Desktop
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault
Library             OperatingSystem
Library             String


*** Variables ***
${OUTPUT_DIR}=      output


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Greet the user
    Download orders file
    ${orders}=    Get orders from CSV file
    Open the Robot ordering website
    FOR    ${order}    IN    @{orders}
        Close pop-up banner
        ${order_values}=    Split String    ${order}    separator=,
        Fill the form for one order    ${order_values}
        Wait Until Keyword Succeeds    10x    1 sec    Preview the robot
        Wait Until Keyword Succeeds    10x    2 sec    Order the robot
        Save order receipt as PDF    ${order_values}[0]
        Save screenshot of a robot
        Add screenshot to PDF    ${order_values}[0]
        Click Button    order-another
    END
    Create a ZIP archive of PDF receipts
    Clean unnecessary files
    Close the robot ordering website


*** Keywords ***
Greet the user
    ${author}=    Get author name
    Add heading    Hello!
    Add text    My name is ${author}, I am an author of this robot.
    Add text input    name    placeholder=Enter your name here:
    ${result}=    Run dialog
    Add text    Nice to meet you ${result.name}. Let us order some robots!
    Show dialog

Get author name
    ${secret}=    Get Secret    credentials
    RETURN    ${secret}[author]

Open the Robot ordering website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close pop-up banner
    Click Button    OK

Download orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders from CSV file
    ${file}=    Get File    orders.csv
    @{read}=    Create List    ${file}
    @{orders}=    Split To Lines    @{read}
    RETURN    ${orders}[1:]

Fill the form for one order
    [Arguments]    ${order_values}
    Select From List By Value    head    ${order_values}[1]
    Click Element    id-body-${order_values}[2]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order_values}[3]
    Input Text    address    ${order_values}[4]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    id:robot-preview-image

Order the robot
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Save screenshot of a robot
    Screenshot    filename=${OUTPUT_DIR}${/}screenshot.png    locator=//*[@id="robot-preview-image"]

Save order receipt as PDF
    [Arguments]    ${order_num}
    ${robot_receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${robot_receipt}    ${OUTPUT_DIR}${/}receipt_${order_num}.pdf

Add screenshot to PDF
    [Arguments]    ${order_num}
    Add Watermark Image To Pdf
    ...    image_path=${OUTPUT_DIR}${/}screenshot.png
    ...    source_path=${OUTPUT_DIR}${/}receipt_${order_num}.pdf
    ...    output_path=${OUTPUT_DIR}${/}receipt_${order_num}.pdf

Create a ZIP archive of PDF receipts
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}receipts.zip    include=*.pdf

Clean unnecessary files
    Remove File    orders.csv
    Remove File    ${OUTPUT_DIR}${/}screenshot.png
    Remove Files    ${OUTPUT_DIR}${/}*.pdf

Close the robot ordering website
    Close Browser
