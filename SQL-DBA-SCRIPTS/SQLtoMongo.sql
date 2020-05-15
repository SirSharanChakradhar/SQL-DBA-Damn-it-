select count(*) from Customers
select count(*) from Employees
select count(*) from Products
select count(*) from Sales

Select top 10
(Employees.FirstName+' '+Employees.LastName) as Sales_person,
(Customers.FirstName+' '+Customers.LastName) as Customer_name,
Products.[Name] as Product_name,
Sales.Quantity as Quantity,
(Sales.Quantity*Products.Price) as Total_price
from sales
inner join Employees
on Sales.SalesPersonID=Employees.EmployeeID
inner join Customers 
on  Sales.CustomerID=Customers.CustomerID
inner join Products
on Sales.ProductID=Products.ProductID
group by Products.[Name],Employees.FirstName,Employees.LastName,Sales.Quantity,Products.Price,Customers.FirstName,Customers.LastName
for json path