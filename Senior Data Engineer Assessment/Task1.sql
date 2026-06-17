PATHCONTAINS (
    dim_employee[ParentPath],
    LOOKUPVALUE (
        dim_employee[EmployeeKey],
        dim_employee[EmployeeEmail],
        USERPRINCIPALNAME()
    )
)
