--select count(*) from Customers
--select count(*) from Employees
--select count(*) from Products
--select count(*) from Sales
select SalesPersonID,CustomerID,ProductID,sum(quantity) from Sales
group by SalesPersonID,CustomerID,ProductID

Select top 20
(Employees.FirstName+' '+Employees.LastName) as Sales_person,
(Customers.FirstName+' '+Customers.LastName) as Customer_name,
Products.[Name] as Product_name,
format(Products.Price,'C','te-IN') as Product_price,
sum(Sales.Quantity) as Quantity,
format(sum(Sales.Quantity)*Products.Price,'C','te-IN') as Total_price
from sales
inner join Employees
on Sales.SalesPersonID=Employees.EmployeeID
inner join Customers 
on  Sales.CustomerID=Customers.CustomerID
inner join Products
on Sales.ProductID=Products.ProductID
group by Products.[Name],Employees.FirstName,Employees.LastName,Products.Price,Customers.FirstName,Customers.LastName
--for json path
--for json auto--, root('sales_report')