import json, os , datetime
from datetime import date

def showDetails(list):
    print ("All Bucket Details")
    for data in list:
        print(data)

def inactiveLargeBucket(list):
    print("-----------------------")
    print("Inactive Large Bucket")
    for data in list:
        print(data)

def showCostReport(report):
    print("-----------------------")
    print("Cost Report (Total cost grouped by region and department):")
    for region, region_data in report.items():
        print(f"\nRegion: {region}")
        for dept, dept_data in region_data.items():
            print(f"  Department: {dept}")
            print(f"    Total Cost: ${dept_data['total_cost']:.2f}")
            if 'recommendations' in dept_data:
                print(f"    Recommendations: {dept_data['recommendations']}")


bucketFile = 'buckets.json'
filePath = os.path.abspath(bucketFile)
with open (filePath,'r') as file:
    filedata = json.load(file)

COST_PER_GB = 0.023
detailsList= []
inactiveLargeBucketList=[]
costReport = {}
inactiveBucketDic = {}
todaysDate = date.today()
threeMonthAgo = todaysDate - datetime.timedelta(days=91)
twentyDaysAgo = todaysDate - datetime.timedelta(days=21)



for data in filedata["buckets"]:
    name = data["name"]
    region = data["region"]
    size = str(data["sizeGB"])
    versioning = str(data["versioning"])
    creationdate = data["createdOn"]
    department = data["tags"]["team"]
    Bucketdetails={
        'BucketName':name,
        "Region":region,
        "BucketSize":size,
        "BucketVersioning":versioning}
    detailsList.append(Bucketdetails)

    creationDate = datetime.datetime.strptime(creationdate,"%Y-%m-%d").date()
    if ((int(size) > 80) and (creationDate < threeMonthAgo)):
            inactiveBucketDic = {
                "region": region,
                "BucketName":name,
                "BucketSize":size +"GB",
                "CreationDate":creationdate}
    if inactiveBucketDic not in inactiveLargeBucketList:
            inactiveLargeBucketList.append(inactiveBucketDic) 

    cost = int(size) * COST_PER_GB

    if region not in costReport:
        costReport[region] = {}
    if department not in costReport[region]:
        costReport[region][department] = {
             "total_cost": 0.0,
             "recommendations": []
        }
    costReport[region][department]["total_cost"] += cost
    if int(size) > 50:
        costReport[region][department]["recommendations"].append(
            f"Bucket '{name}' (Size: {size} GB) - Recommend cleanup operations."
        )
    
    if int(size) > 100 and creationDate < twentyDaysAgo:
        costReport[region][department]["recommendations"].append(
            f"Bucket '{name}' (Size: {size} GB) - Add to deletion queue (not accessed in 20+ days)."
        )
    


showDetails(detailsList)
inactiveLargeBucket(inactiveLargeBucketList)
showCostReport(costReport)


