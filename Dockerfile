FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

COPY Sybau_Backend/Sybau_Backend/*.csproj ./
RUN dotnet restore

COPY Sybau_Backend/Sybau_Backend/ ./
RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/out ./
ENTRYPOINT ["dotnet", "Sybau_Backend.dll"]
